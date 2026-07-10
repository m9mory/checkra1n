import SwiftUI

// MARK: - Package manager

enum PackageManager: String, CaseIterable {
    case sileo  = "Sileo"
    case cydia  = "Cydia"
    case zebra  = "Zebra"
}

// MARK: - Boot phases

enum BootPhase {
    case blackout     // 0–3 s: nothing
    case appleLogo    // 3–4 s: Apple logo
    case bothLogos    // 4+ s: Apple + user logo together
}

// MARK: - App states

enum AppState: Equatable {
    case welcome
    case booting
    case jailbreaking
    case postJailbreak(PostPhase)
    case result(city: String, isRaining: Bool, temp: Double, description: String)

    enum PostPhase: Equatable {
        case blackout
        case appleLogo
    }
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
            case .postJailbreak(let phase):
                postJailbreakScreen(phase: phase)
            case let .result(city, isRaining, temp, description):
                resultScreen(city: city, isRaining: isRaining,
                             temp: temp, description: description)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: appState)
        .statusBar(hidden: hideStatusBar)
    }

    private var hideStatusBar: Bool {
        switch appState {
        case .welcome, .result: return false
        default: return true
        }
    }

    // MARK: - Welcome screen

    var welcomeScreen: some View {
        VStack(spacing: 0) {
            Spacer()

            // User logo (same as boot)
            logoView
                .frame(width: 90, height: 90)

            Text("checkra1n")
                .font(.custom("Menlo", size: 34))
                .foregroundColor(.white)
                .fontWeight(.bold)
                .padding(.top, 20)

            Text("0.13.3 beta")
                .font(.custom("Menlo", size: 13))
                .foregroundColor(.white.opacity(0.55))
                .padding(.top, 4)

            VStack(spacing: 2) {
                Text("A5 – A19  ·  iOS 12.0 – 27.0")
                Text("iPhone 4S – iPhone 17 Pro Max")
            }
            .font(.custom("Menlo", size: 11))
            .foregroundColor(.white.opacity(0.35))
            .padding(.top, 16)

            VStack(spacing: 6) {
                Text("Менеджер пакетов")
                    .font(.custom("Menlo", size: 11))
                    .foregroundColor(.white.opacity(0.45))

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
                            .fill(Color.white)
                    )
            }
            .padding(.bottom, 70)
        }
    }

    // MARK: - PM button

    func pmButton(_ pm: PackageManager) -> some View {
        let isSelected = selectedPM == pm
        let borderColor: Color = {
            switch pm {
            case .sileo: return Color(red: 0.2, green: 0.75, blue: 0.85)
            case .cydia: return Color(red: 0.7, green: 0.4, blue: 0.2)
            case .zebra: return Color(red: 0.55, green: 0.55, blue: 0.55)
            }
        }()
        let pmImage = UIImage(named: pm.rawValue.lowercased())

        return Button(action: { selectedPM = pm }) {
            VStack(spacing: 6) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(isSelected ? borderColor.opacity(0.25) : Color.white.opacity(0.06))
                        .frame(width: 60, height: 60)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(isSelected ? borderColor : Color.white.opacity(0.15),
                                        lineWidth: isSelected ? 2 : 1)
                        )

                    if let img = pmImage {
                        Image(uiImage: img)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 40, height: 40)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    } else {
                        Image(systemName: "app.fill")
                            .font(.system(size: 24))
                            .foregroundColor(isSelected ? borderColor : .gray)
                    }
                }
                Text(pm.rawValue)
                    .font(.custom("Menlo", size: 10))
                    .foregroundColor(isSelected ? borderColor : .gray)
            }
        }
    }

    // MARK: - Boot sequence

    func startBootSequence() {
        appState = .booting
        bootPhase = .blackout

        // 0→3s: blackout → Apple logo
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            guard appState == .booting else { return }
            withAnimation(nil) { bootPhase = .appleLogo }
        }
        // 3→4s: Apple → both logos
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            guard appState == .booting else { return }
            withAnimation(nil) { bootPhase = .bothLogos }
        }
        // 5s: start jailbreak
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            guard appState == .booting else { return }
            withAnimation(nil) { appState = .jailbreaking }
            viewModel.startJailbreak(packageManager: selectedPM) { city, isRaining, temp, desc in
                // Logs finished → post-jailbreak
                startPostJailbreak(city: city, isRaining: isRaining,
                                   temp: temp, description: desc)
            }
        }
    }

    func startPostJailbreak(city: String, isRaining: Bool,
                            temp: Double, description: String) {
        appState = .postJailbreak(.blackout)

        // 2s blackout
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            guard case .postJailbreak = appState else { return }
            withAnimation(nil) { appState = .postJailbreak(.appleLogo) }
        }
        // 5s total → weather
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            guard case .postJailbreak = appState else { return }
            withAnimation(.easeInOut(duration: 0.6)) {
                appState = .result(city: city, isRaining: isRaining,
                                   temp: temp, description: description)
            }
        }
    }

    // MARK: - Boot screen

    var bootScreen: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // Apple logo — slightly higher
            appleLogoView
                .offset(y: -30)
                .opacity(bootPhase == .appleLogo || bootPhase == .bothLogos ? 1 : 0)

            // User logo — lower-left from apple center
            if bootPhase == .bothLogos {
                logoView
                    .frame(width: 100, height: 100)
                    .offset(x: -8, y: 40)
                    .transition(.identity)
            }
        }
        .animation(.none, value: bootPhase)
    }

    // MARK: - Jailbreak screen

    var jailbreakScreen: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // Full-screen logs — no padding, covers everything
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(Array(viewModel.logLines.enumerated()), id: \.offset) { idx, line in
                            Text(line)
                                .font(.custom("Menlo", size: 8))
                                .foregroundColor(.white)
                                .id(idx)
                        }
                    }
                }
                .onChange(of: viewModel.logLines.count) { _ in
                    if let last = viewModel.logLines.indices.last {
                        withAnimation(.linear(duration: 0.02)) {
                            proxy.scrollTo(last, anchor: .bottom)
                        }
                    }
                }
            }

            // Apple logo higher, user logo lower-left
            appleLogoView
                .offset(y: -30)
                .allowsHitTesting(false)
            logoView
                .frame(width: 100, height: 100)
                .offset(x: -8, y: 40)
                .allowsHitTesting(false)
        }
    }

    // MARK: - Post-jailbreak screen

    func postJailbreakScreen(phase: AppState.PostPhase) -> some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if phase == .appleLogo {
                appleLogoView
            }
        }
        .animation(.none, value: phase)
    }

    // MARK: - Result screen

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
                .foregroundColor(.white)
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
                .foregroundColor(.white.opacity(0.3))
                .padding(.bottom, 50)
        }
    }

    // MARK: - Shared views

    var appleLogoView: some View {
        Image(systemName: "applelogo")
            .font(.system(size: 90))
            .foregroundColor(.white)
    }

    /// User icon from bundle — loaded via UIImage(named:)
    @ViewBuilder
    var logoView: some View {
        if let img = loadLogoImage() {
            Image(uiImage: img)
                .resizable()
                .aspectRatio(contentMode: .fit)
        }
    }

    private func loadLogoImage() -> UIImage? {
        if let img = UIImage(named: "logo") { return img }
        if let path = Bundle.main.path(forResource: "logo", ofType: "png"),
           let img = UIImage(contentsOfFile: path) { return img }
        if let url = Bundle.main.url(forResource: "logo", withExtension: "png"),
           let data = try? Data(contentsOf: url),
           let img = UIImage(data: data) { return img }
        return nil
    }
}
