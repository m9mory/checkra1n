import SwiftUI

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
                Text("A5 – A13  ·  iOS 12.0 – 17.6.1")
                Text("iPhone 4S – iPhone 14 Pro Max")
            }
            .font(.custom("Menlo", size: 11))
            .foregroundColor(.green.opacity(0.35))
            .padding(.top, 16)

            Spacer()

            // Start button
            Button(action: {
                appState = .jailbreaking
                viewModel.startJailbreak { city, isRaining, temp, desc in
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

            // City name
            Text(city)
                .font(.custom("Menlo", size: 28))
                .foregroundColor(.white.opacity(0.7))
                .padding(.bottom, 16)

            // Big rain status
            Text(isRaining ? "ДОЖДЬ\nИДЁТ" : "ДОЖДЯ\nНЕТ")
                .font(.custom("Menlo", size: isRaining ? 46 : 50))
                .fontWeight(.bold)
                .foregroundColor(isRaining ? .white : .green)
                .multilineTextAlignment(.center)
                .padding(.bottom, 20)

            // Temperature & description
            HStack(spacing: 12) {
                Text(description)
                Text("·")
                Text(String(format: "%.1f°C", temp))
            }
            .font(.custom("Menlo", size: 14))
            .foregroundColor(.white.opacity(0.5))

            Spacer()

            // Subtle footer
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
