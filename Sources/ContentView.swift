import SwiftUI

// MARK: - Package manager

enum PackageManager: String, CaseIterable {
    case sileo  = "Sileo"
    case cydia  = "Cydia"
    case zebra  = "Zebra"
}

// MARK: - App states

enum AppState: Equatable {
    case welcome
    case jailbreaking
    case result(city: String, isRaining: Bool, temp: Double, description: String)
}

// MARK: - Content view

struct ContentView: View {
    @StateObject private var viewModel = JailbreakViewModel()
    @State private var appState: AppState = .welcome
    @State private var selectedPM: PackageManager = .sileo

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            switch appState {
            case .welcome:
                welcomeScreen
            case .jailbreaking:
                jailbreakScreen
            case let .result(city, isRaining, temp, description):
                resultScreen(city: city, isRaining: isRaining,
                             temp: temp, description: description)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: appState)
    }

    // MARK: - Welcome screen

    var welcomeScreen: some View {
        VStack(spacing: 0) {
            Spacer()

            // Logo — circle with checkmark (checkra1n style)
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

            // Package manager picker
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

            // Start button
            Button(action: {
                appState = .jailbreaking
                viewModel.startJailbreak(packageManager: selectedPM) { city, isRaining, temp, desc in
                    withAnimation(.easeInOut(duration: 0.6)) {
                        appState = .result(city: city, isRaining: isRaining,
                                           temp: temp, description: desc)
                    }
                }
            }) {
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
            case .sileo: return ("app.badge.fill", Color(red: 0.2, g: 0.75, b: 0.85))
            case .cydia: return ("shippingbox.fill", Color(red: 0.7, g: 0.4, b: 0.2))
            case .zebra: return ("square.grid.3x3.fill", Color(red: 0.55, g: 0.55, b: 0.55))
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

    // MARK: - Jailbreak screen (logs)

    var jailbreakScreen: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 1) {
                    ForEach(Array(viewModel.logLines.enumerated()), id: \.offset) { idx, line in
                        Text(highlightLine(line))
                            .font(.custom("Menlo", size: 10))
                            .foregroundColor(.green)
                            .id(idx)
                    }
                }
                .padding(.horizontal, 6)
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
        attr.foregroundColor = .green
        for marker in ["[*]", "[✓]", "[!]", "[+]", "[-]", "[?]"] {
            if let range = attr.range(of: marker) {
                attr[range].foregroundColor = .white
                attr[range].font = .custom("Menlo", size: 10).bold()
            }
        }
        return attr
    }
}
