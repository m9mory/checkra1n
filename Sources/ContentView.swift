import SwiftUI

// MARK: - Package manager

enum PackageManager: String, CaseIterable {
    case sileo  = "Sileo"
    case cydia  = "Cydia"
    case zebra  = "Zebra"
}

// MARK: - Boot phases

enum BootPhase {
    case blackout     // 0–3 s: pure black
    case appleLogo    // 3–4 s: Apple logo fades in
    case checkra1n    // 4–5 s: checkra1n logo replaces Apple
}

// MARK: - App states

enum AppState: Equatable {
    case welcome
    case booting
    case jailbreaking
    case result(city: String, isRaining: Bool, temp: Double, description: String)
}

// MARK: - Content view

struct ContentView: View {
    @StateObject private var viewModel = JailbreakViewModel()
    @State private var appState: AppState = .welcome
    @State private var selectedPM: PackageManager = .sileo
    @State private var bootPhase: BootPhase = .blackout

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            switch appState {
            case .welcome:
                welcomeScreen
            case .booting:
                bootScreen
            case .jailbreaking:
                jailbreakScreen
            case let .result(city, isRaining, temp, description):
                resultScreen(city: city, isRaining: isRaining,
                             temp: temp, description: description)
            }

            // Single persistent logo — user icon with fallback
            logoView
                .opacity(persistentLogoOpacity)
                .allowsHitTesting(false)
                .animation(.none, value: bootPhase)
                .animation(.none, value: appState)
        }
        .animation(.easeInOut(duration: 0.3), value: appState)
        .statusBar(hidden: appState == .booting || appState == .jailbreaking)
    }

    /// Logo visible during boot (checkra1n phase) and jailbreak
    private var showPersistentLogo: Bool {
        switch appState {
        case .booting: return bootPhase == .checkra1n
        case .jailbreaking: return true
        default: return false
        }
    }

    /// Full opacity during boot, faded during jailbreak
    private var persistentLogoOpacity: Double {
        switch appState {
        case .booting: return 1.0
        case .jailbreaking: return 0.28
        default: return 0
        }
    }

    /// Logo: user icon loaded by every possible method
    @ViewBuilder
    private var logoView: some View {
        if let img = loadLogoImage() {
            Image(uiImage: img)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 80, height: 80)
        } else {
            Circle()
                .fill(Color.red)
                .frame(width: 80, height: 80)
        }
    }

    private func loadLogoImage() -> UIImage? {
        // 1) Asset catalog or bundle root
        if let img = UIImage(named: "logo") { return img }
        // 2) Direct file path
        if let path = Bundle.main.path(forResource: "logo", ofType: "png"),
           let img = UIImage(contentsOfFile: path) { return img }
        // 3) URL with Data
        if let url = Bundle.main.url(forResource: "logo", withExtension: "png"),
           let data = try? Data(contentsOf: url),
           let img = UIImage(data: data) { return img }
        // 4) App icon fallback
        if let img = UIImage(named: "AppIcon60x60") { return img }
        return nil
    }

    // MARK: - Welcome screen

    var welcomeScreen: some View {
        VStack(spacing: 0) {
            Spacer()

            ZStack {
                Circle()
                    .stroke(Color.green, lineWidth: 3)
                    .frame(width: 90, height: 90)

                Image(systemName: "checkmark")
                    .font(.system(size: 42, weight: .bold))
                    .foregroundColor(.green)
            }

            Text("checkra1n")
                .font(.custom("Menlo", size: 34))
                .foregroundColor(.green)
                .fontWeight(.bold)
                .padding(.top, 20)

            Text("0.13.3 beta")
                .font(.custom("Menlo", size: 13))
                .foregroundColor(.green.opacity(0.55))
                .padding(.top, 4)

            VStack(spacing: 2) {
                Text("A5 – A19  ·  iOS 12.0 – 27.0")
                Text("iPhone 4S – iPhone 17 Pro Max")
            }
            .font(.custom("Menlo", size: 11))
            .foregroundColor(.green.opacity(0.35))
            .padding(.top, 16)

            VStack(spacing: 6) {
                Text("Менеджер пакетов")
                    .font(.custom("Menlo", size: 11))
                    .foregroundColor(.green.opacity(0.45))

                HStack(spacing: 20) {
                    ForEach(PackageManager.allCases, id: \.self) { pm in
                        pmButton(pm)
                    }
                }
            }
            .padding(.top, 24)

            Spacer()

            Button(action: { startBootSequence() }) {
                Text("Начать джейлбрейк")
                    .font(.custom("Menlo", size: 17))
                    .foregroundColor(.black)
                    .padding(.horizontal, 44)
                    .padding(.vertical, 15)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.green)
                    )
            }
            .padding(.bottom, 70)
        }
    }

    // MARK: - PM button

    func pmButton(_ pm: PackageManager) -> some View {
        let isSelected = selectedPM == pm
        let (symbol, color): (String, Color) = {
            switch pm {
            case .sileo: return ("app.badge.fill", Color(red: 0.2, green: 0.75, blue: 0.85))
            case .cydia: return ("shippingbox.fill", Color(red: 0.7, green: 0.4, blue: 0.2))
            case .zebra: return ("square.grid.3x3.fill", Color(red: 0.55, green: 0.55, blue: 0.55))
            }
        }()

        return Button(action: { selectedPM = pm }) {
            VStack(spacing: 6) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(isSelected ? color.opacity(0.25) : Color.white.opacity(0.06))
                        .frame(width: 60, height: 60)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(isSelected ? color : Color.white.opacity(0.15), lineWidth: isSelected ? 2 : 1)
                        )

                    Image(systemName: symbol)
                        .font(.system(size: 24))
                        .foregroundColor(isSelected ? color : .gray)
                }

                Text(pm.rawValue)
                    .font(.custom("Menlo", size: 10))
                    .foregroundColor(isSelected ? color : .gray)
            }
        }
    }

    // MARK: - Boot sequence

    func startBootSequence() {
        appState = .booting
        bootPhase = .blackout

        // Phase 1→2: blackout → Apple logo (after 3 s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            guard appState == .booting else { return }
            withAnimation(.easeIn(duration: 0.4)) { bootPhase = .appleLogo }
        }

        // Phase 2→3: Apple → checkra1n logo (after 4 s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            guard appState == .booting else { return }
            withAnimation(.easeInOut(duration: 0.5)) { bootPhase = .checkra1n }
        }

        // Phase 3→jailbreak: start logs (after 5.5 s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.5) {
            guard appState == .booting else { return }
            withAnimation(.easeInOut(duration: 0.3)) { appState = .jailbreaking }
            viewModel.startJailbreak(packageManager: selectedPM) { city, isRaining, temp, desc in
                withAnimation(.easeInOut(duration: 0.6)) {
                    appState = .result(city: city, isRaining: isRaining,
                                       temp: temp, description: desc)
                }
            }
        }
    }

    var bootScreen: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // Apple logo — no animation, appears/disappears instantly
            Image(systemName: "applelogo")
                .font(.system(size: 100))
                .foregroundColor(.white)
                .opacity(bootPhase == .appleLogo ? 1 : 0)
                .offset(y: -40)
                .animation(.none, value: bootPhase)
        }
    }

    // MARK: - Jailbreak screen (centered logo, logs overlaid)

    var jailbreakScreen: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 1) {
                    ForEach(Array(viewModel.logLines.enumerated()), id: \.offset) { idx, line in
                        Text(highlightLine(line))
                            .font(.custom("Menlo", size: 10))
                            .foregroundColor(.white)
                            .id(idx)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.top, 14)
                .padding(.bottom, 40)
            }
            .onChange(of: viewModel.logLines.count) { _ in
                if let last = viewModel.logLines.indices.last {
                    withAnimation(.linear(duration: 0.05)) {
                        proxy.scrollTo(last, anchor: .bottom)
                    }
                }
            }
        }
        .background(Color.black.opacity(0.92))
    }

    // MARK: - Result screen (full-screen weather)

    func resultScreen(city: String, isRaining: Bool,
                      temp: Double, description: String) -> some View {
        VStack(spacing: 0) {
            Spacer()

            Text(city)
                .font(.custom("Menlo", size: 28))
                .foregroundColor(.white.opacity(0.7))
                .padding(.bottom, 16)

            Text(isRaining ? "ДОЖДЬ\nИДЁТ" : "ДОЖДЯ\nНЕТ")
                .font(.custom("Menlo", size: isRaining ? 46 : 50))
                .fontWeight(.bold)
                .foregroundColor(isRaining ? .white : .green)
                .multilineTextAlignment(.center)
                .padding(.bottom, 20)

            HStack(spacing: 12) {
                Text(description)
                Text("·")
                Text(String(format: "%.1f°C", temp))
            }
            .font(.custom("Menlo", size: 14))
            .foregroundColor(.white.opacity(0.5))

            Spacer()

            Text("checkra1n 0.13.3 beta")
                .font(.custom("Menlo", size: 10))
                .foregroundColor(.green.opacity(0.3))
                .padding(.bottom, 50)
        }
    }

    // MARK: - Helpers

    private func highlightLine(_ line: String) -> AttributedString {
        var attr = AttributedString(line)
        attr.foregroundColor = .white
        for marker in ["[*]", "[✓]", "[!]", "[+]", "[-]", "[?]"] {
            if let range = attr.range(of: marker) {
                attr[range].foregroundColor = .white
                attr[range].font = .custom("Menlo", size: 9).bold()
            }
        }
        return attr
    }
}
