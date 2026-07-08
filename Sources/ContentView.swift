import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = JailbreakViewModel()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // Terminal log output
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 1) {
                            ForEach(Array(viewModel.logLines.enumerated()), id: \.offset) { idx, line in
                                Text(attributedLine(line))
                                    .font(.custom("Menlo", size: 11))
                                    .foregroundColor(.green)
                                    .id(idx)
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.top, 12)
                    }
                    .onChange(of: viewModel.logLines.count) { _ in
                        if let last = viewModel.logLines.indices.last {
                            withAnimation(.easeOut(duration: 0.15)) {
                                proxy.scrollTo(last, anchor: .bottom)
                            }
                        }
                    }
                }

                Spacer()

                // Weather result
                if viewModel.isFetchingWeather {
                    HStack(spacing: 6) {
                        ProgressView()
                            .scaleEffect(0.7)
                            .tint(.green)
                        Text("Fetching diagnostics...")
                            .font(.custom("Menlo", size: 12))
                            .foregroundColor(.green)
                    }
                    .padding(.vertical, 8)
                }

                if let weather = viewModel.weatherText, !viewModel.isFetchingWeather {
                    VStack(spacing: 4) {
                        Rectangle()
                            .fill(Color.green.opacity(0.3))
                            .frame(height: 1)

                        Text(weather)
                            .font(.custom("Menlo", size: 14))
                            .foregroundColor(.white)
                            .padding(.vertical, 10)
                    }
                    .padding(.horizontal, 16)
                }

                // Jailbreak button
                Button(action: {
                    viewModel.startJailbreak()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "terminal")
                            .font(.system(size: 14))
                        Text("Начать джейлбрейк")
                            .font(.custom("Menlo", size: 16))
                    }
                    .foregroundColor(.black)
                    .padding(.horizontal, 36)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(viewModel.isRunning ? Color.gray : Color.green)
                    )
                }
                .disabled(viewModel.isRunning)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            viewModel.startJailbreak()
        }
    }

    /// Color brackets and key symbols green-bright, dim the rest slightly
    private func attributedLine(_ line: String) -> AttributedString {
        var attr = AttributedString(line)
        attr.foregroundColor = .green
        // Highlight [*]  [✓]  [!]  [+]  [-] markers
        let markers = ["[*]", "[✓]", "[!]", "[+]", "[-]", "[?]"]
        for marker in markers {
            if let range = attr.range(of: marker) {
                attr[range].foregroundColor = .white
                attr[range].font = .custom("Menlo", size: 11).bold()
            }
        }
        return attr
    }
}
