import Foundation
import Combine

final class JailbreakViewModel: ObservableObject {
    @Published var logLines: [String] = []
    @Published var weatherText: String? = nil
    @Published var isRunning = false
    @Published var isFetchingWeather = false

    private var workItems: [DispatchWorkItem] = []

    // MARK: - Public

    func startJailbreak() {
        cancelAll()
        isRunning = true
        weatherText = nil
        logLines.removeAll()

        let bootLogs: [String] = [
            "[*] checkra1n 0.13.3 beta — \"odyssey edition\"",
            "[*] Initializing...",
            "[*] Device: iPhone12,1",
            "[*] iOS version: 14.8.1 (18H107)",
            "[*] Build: checkra1n-0.13.3~beta",
            "",
        ]

        let modules: [String] = [
            "PongoOS", "kernel_loader", "trustcache",
            "amfid_patch", "sandbox_patch", "rootfs",
            "substitute", "libhooker", "Sileo", "dpkg",
        ]

        var delay: Double = 0

        // Boot banner
        for log in bootLogs {
            schedule(delay: delay) { self.logLines.append(log) }
            delay += log.isEmpty ? 0.1 : 0.25
        }

        // Modules
        for mod in modules {
            schedule(delay: delay) {
                self.logLines.append("[+] Loading \(mod)...")
            }
            delay += Double.random(in: 0.18...0.45)
            schedule(delay: delay) {
                self.logLines.append("[✓] \(mod) OK")
            }
            delay += Double.random(in: 0.10...0.25)
        }

        // Exploit chain
        let exploitLogs: [String] = [
            "",
            "[*] Exploiting checkm8 (A13 Bionic)...",
            "[✓] checkm8 SUCCESS — device entered DFU mode",
            "[*] Setting up TCP tunnel over USB...",
            "[*] Booting PongoOS...",
            "[✓] PongoOS handshake OK",
        ]
        for log in exploitLogs {
            schedule(delay: delay) { self.logLines.append(log) }
            delay += log.isEmpty ? 0.1 : 0.3
        }

        // Random progress logs
        for _ in 0..<18 {
            let log = randomProgressLog()
            schedule(delay: delay) { self.logLines.append(log) }
            delay += Double.random(in: 0.08...0.35)
        }

        // Completion
        schedule(delay: delay) {
            self.logLines.append("")
            self.logLines.append("[✓] All patches applied successfully")
            self.logLines.append("[✓] Jailbreak complete — enjoy your freedom 🏴‍☠️")
            self.logLines.append("")
            self.isRunning = false
        }
        delay += 1.0

        // Weather fetch (~5 s total)
        schedule(delay: delay) {
            self.logLines.append("[*] Fetching device diagnostics...")
            self.fetchWeatherInfo()
        }
    }

    // MARK: - Helpers

    private func schedule(delay: Double, block: @escaping () -> Void) {
        let item = DispatchWorkItem(block: block)
        workItems.append(item)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: item)
    }

    private func cancelAll() {
        for item in workItems { item.cancel() }
        workItems.removeAll()
    }

    private func randomProgressLog() -> String {
        [
            "Patching kernel... 47%",
            "Patching kernel... 73%",
            "Patching kernel... 91%",
            "Patching kernel... 100%",
            "Kernel slide: 0x00000000028dc000",
            "Setting nonce generator...",
            "APTicket verified",
            "Boot nonce set: 0xdeadbeefcafebabe",
            "Allocated trampoline at 0xfffffff008340000",
            "Hooking sysent table...",
            "Mounting /dev/disk0s1s1 as /private/var",
            "Remounting rootfs as r/w...",
            "Signature check bypassed",
            "AMFI patched successfully",
            "Copying trust cache...",
            "Installing bootstrap...",
            "Injecting payload into launchd...",
            "Cleaning up kernel state...",
            "Respring required — skipping",
            "Initializing Cydia repos...",
            "Running uicache --all",
            "Restoring virtual memory map...",
            "SIGBUS at 0xfffff0008370 — handled",
            "panic(cpu 2): double fault — recovered",
            "iBoot patch applied",
            "Trampoline page mapped R/W/X",
            "Sandbox hook installed @ 0xfffffff00978a000",
            "TF_PLATFORM flag set on /Applications",
            "cs_enforcement_disable = 1",
            "PE_i_can_has_debugger = 1",
        ].randomElement()!
    }

    // MARK: - Networking

    private func fetchWeatherInfo() {
        isFetchingWeather = true

        Task {
            do {
                // 1) Geolocate by IP
                let ipURL = URL(string: "https://ipapi.co/json/")!
                let (ipData, _) = try await URLSession.shared.data(from: ipURL)

                guard let ipJson = try JSONSerialization.jsonObject(with: ipData) as? [String: Any],
                      let city = ipJson["city"] as? String,
                      let lat = ipJson["latitude"] as? Double,
                      let lon = ipJson["longitude"] as? Double else {
                    await setWeather("Не удалось определить город")
                    return
                }

                // 2) Weather from Open-Meteo (no API key needed)
                let meteoURL = URL(string:
                    "https://api.open-meteo.com/v1/forecast?latitude=\(lat)&longitude=\(lon)&current_weather=true")!
                let (meteoData, _) = try await URLSession.shared.data(from: meteoURL)

                guard let meteoJson = try JSONSerialization.jsonObject(with: meteoData) as? [String: Any],
                      let current = meteoJson["current_weather"] as? [String: Any],
                      let code = current["weathercode"] as? Int,
                      let temp = current["temperature"] as? Double else {
                    await setWeather("\(city): не удалось загрузить погоду")
                    return
                }

                let isRaining = (51...99).contains(code)
                let rainText = isRaining ? "Идёт дождь" : "Дождя нет"
                let desc = weatherDescription(code)
                let tempStr = String(format: "%.1f°C", temp)

                await setWeather("\(city): \(rainText) · \(desc) · \(tempStr)")
            } catch {
                await setWeather("Ошибка сети: \(error.localizedDescription)")
            }
        }
    }

    @MainActor
    private func setWeather(_ text: String) {
        logLines.append("[i] \(text)")
        weatherText = text
        isFetchingWeather = false
    }

    private func weatherDescription(_ code: Int) -> String {
        switch code {
        case 0:  return "Ясно"
        case 1,2,3: return "Облачно"
        case 45,48: return "Туман"
        case 51,53,55: return "Морось"
        case 61,63,65: return "Дождь"
        case 66,67: return "Ледяной дождь"
        case 71,73,75: return "Снег"
        case 77: return "Град"
        case 80,81,82: return "Ливень"
        case 85,86: return "Снегопад"
        case 95: return "Гроза"
        case 96,99: return "Гроза с градом"
        default: return "Неизвестно"
        }
    }
}
