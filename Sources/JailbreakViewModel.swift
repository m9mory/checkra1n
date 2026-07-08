import Foundation

final class JailbreakViewModel: ObservableObject {
    @Published var logLines: [String] = []

    private var workItems: [DispatchWorkItem] = []

    // MARK: - Public

    func startJailbreak(
        packageManager pm: PackageManager,
        onComplete: @escaping (_ city: String, _ isRaining: Bool,
                               _ temp: Double, _ desc: String) -> Void
    ) {
        cancelAll()
        logLines.removeAll()

        let bootLogs: [String] = [
            "[*] checkra1n 0.13.3 beta — \"odyssey edition\"",
            "[*] Initializing exploit environment...",
            "[*] Device: iPhone18,1 (A19 Pro)",
            "[*] iOS version: 27.0 (24A335)",
            "[*] Build: checkra1n-0.13.3~beta+20260708",
            "[*] Compiler: Apple clang 17.0 (arm64e)",
            "",
            "[*] Enumerating USB devices...",
            "[✓] DFU device found @ 0x05ac:0x12a8",
            "[*] Requesting SHSH blobs from TSS...",
        ]

        let modules: [String] = [
            "PongoOS", "kernel_loader", "trustcache",
            "amfid_patch", "sandbox_patch", "rootfs",
            "substitute", "libhooker", pm.rawValue, "dpkg",
            "jailbreakd", "pwn20wnd", "uikittools",
        ]

        let exploitChain: [String] = [
            "",
            "[*] Exploiting checkm8 (A19 Pro, t8140)...",
            "[*] Setting up heap feng-shui...",
            "[✓] use-after-free triggered @ 0xfffffff00837a000",
            "[✓] checkm8 SUCCESS — device entered pwned DFU",
            "[*] Uploading iBSS payload...",
            "[✓] iBSS running — booting PongoOS...",
            "[*] Handshaking with PongoOS...",
            "[✓] PongoOS v2.9.3 alive",
            "[*] Pushing kernel patchset (1 247 patches)...",
            "[✓] Kernelcache decompressed: 47 MB",
        ]

        let lateLogs: [String] = [
            "",
            "[*] Finalising jailbreak...",
            "[*] Running ldrestart...",
            "[✓] Daemons reloaded",
            "[*] Injecting into SpringBoard...",
            "[✓] \(pm.rawValue) installed successfully",
            "[✓] All patches applied successfully",
            "[✓] Jailbreak complete! 🏴‍☠️",
            "",
            "[*] Sending anonymised diagnostics...",
        ]

        var delay: Double = 0

        // Boot
        for log in bootLogs {
            schedule(delay: delay) { self.logLines.append(log) }
            delay += log.isEmpty ? 0.04 : 0.10
        }

        // Modules (fast)
        for mod in modules {
            schedule(delay: delay) { self.logLines.append("[+] Loading \(mod)...") }
            delay += Double.random(in: 0.04...0.10)
            schedule(delay: delay) { self.logLines.append("[✓] \(mod) OK") }
            delay += Double.random(in: 0.02...0.06)
        }

        // Exploit
        for log in exploitChain {
            schedule(delay: delay) { self.logLines.append(log) }
            delay += log.isEmpty ? 0.04 : 0.12
        }

        // Random progress (a lot, fast)
        for _ in 0..<45 {
            let log = randomProgressLog()
            schedule(delay: delay) { self.logLines.append(log) }
            delay += Double.random(in: 0.02...0.08)
        }

        // Late
        for log in lateLogs {
            schedule(delay: delay) { self.logLines.append(log) }
            delay += log.isEmpty ? 0.04 : 0.12
        }

        // Weather
        schedule(delay: delay) {
            self.fetchWeatherInfo(onComplete: onComplete)
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
            // Kernel patching
            "Patching kernel... 18%",
            "Patching kernel... 34%",
            "Patching kernel... 47%",
            "Patching kernel... 61%",
            "Patching kernel... 73%",
            "Patching kernel... 85%",
            "Patching kernel... 92%",
            "Patching kernel... 100%",
            // Memory
            "Kernel slide: 0x00000000028dc000",
            "Kernel base: 0xfffffff007604000",
            "Allocated trampoline at 0xfffffff008340000",
            "Trampoline page remapped R/W/X",
            "Virtual memory region: 0xfffffff008300000–0xfffffff0083fffff",
            "Restoring virtual memory map...",
            // Boot
            "Setting nonce generator (A19)...",
            "APTicket verified successfully",
            "Boot nonce set: 0xdeadbeefcafebabe",
            "iBoot patchset #3 applied",
            // AMFI / sandbox
            "AMFI: cs_enforcement_disable = 1",
            "AMFI: PE_i_can_has_debugger = 1",
            "Sandbox hook installed @ 0xfffffff00978a000",
            "Sandbox: MACF policy #2 relaxed",
            "Signature check bypassed (AMFI patch)",
            // Filesystem
            "Mounting /dev/disk0s1s1 as /private/var",
            "Remounting rootfs as r/w...",
            "TF_PLATFORM flag set on /Applications",
            "Copying trust cache...",
            "Trust cache: 247 hashes injected",
            // Tweaks
            "Hooking sysent table (n=512)...",
            "Installing bootstrap packages...",
            "Cydia repo: https://apt.bingner.com",
            "Cydia repo: https://repo.chariz.com",
            "Sileo: registered 7 package sources",
            "Running uicache --all --respring",
            "libhooker: 14 tweak dylibs loaded",
            "Injecting payload into launchd (pid 1)...",
            "Cleaning up kernel state...",
            // Panic (fake)
            "panic(cpu 2 caller 0xfffffff008a1b4c0): \"double fault\" @ xnu-8796.141.3",
            "Debugger called: <panic> — ignoring (patched)",
            "SIGBUS at 0xfffff0008370 — signal handled",
            "SIGILL  at 0xfffffff0077000a8 — recovered",
            "Kernel trap #14 (page fault) — expected, skipping",
            // Misc
            "AppleKeyStore: locked — unlocking...",
            "SEP firmware: SEPOS 2024.08 (patched)",
            "iBoot-9239.140.4 — nonce set OK",
            "Restoring host TCP stack...",
            "USB serial #: CPID:0x8960 CPRV:0x11 CPFM:0x03 SCEP:0x01 BDID:0x08 ECID:0xdeadbeef",
            "IOAESAccelerator: hardware AES ready",
            "[?] Unknown symbol _csblob_entitlements_dictionary_set — patching",
        ].randomElement()!
    }

    // MARK: - Networking

    private func fetchWeatherInfo(
        onComplete: @escaping (_ city: String, _ isRaining: Bool,
                               _ temp: Double, _ desc: String) -> Void
    ) {
        Task {
            let (city, lat, lon) = await fetchLocation()

            guard let lat, let lon else {
                await done(onComplete, city: city,
                           raining: false, temp: 0, desc: "Нет данных")
                return
            }

            do {
                let meteoURL = URL(string:
                    "https://api.open-meteo.com/v1/forecast?latitude=\(lat)&longitude=\(lon)&current_weather=true")!
                let (meteoData, _) = try await URLSession.shared.data(from: meteoURL)

                guard let meteoJson = try JSONSerialization.jsonObject(with: meteoData) as? [String: Any],
                      let current = meteoJson["current_weather"] as? [String: Any],
                      let code = current["weathercode"] as? Int,
                      let temp = current["temperature"] as? Double else {
                    await done(onComplete, city: city,
                               raining: false, temp: 0, desc: "Нет данных")
                    return
                }

                let isRaining = (51...99).contains(code)
                let desc = weatherDescription(code)

                await done(onComplete, city: city,
                           raining: isRaining, temp: temp, desc: desc)
            } catch {
                await done(onComplete, city: city,
                           raining: false, temp: 0, desc: error.localizedDescription)
            }
        }
    }

    /// Try multiple IP-geolocation APIs; Russia-friendly chain.
    private func fetchLocation() async -> (city: String, lat: Double?, lon: Double?) {
        // 1) ip-api.com — free, no key, works in Russia
        if let loc = await tryLocation(
            url: "http://ip-api.com/json/?fields=city,lat,lon",
            cityKey: "city", latKey: "lat", lonKey: "lon"
        ) { return loc }

        // 2) ipwho.is — fallback
        if let loc = await tryLocation(
            url: "https://ipwho.is/json",
            cityKey: "city", latKey: "latitude", lonKey: "longitude"
        ) { return loc }

        // 3) freeipapi.com — second fallback
        if let loc = await tryLocation(
            url: "https://freeipapi.com/api/json",
            cityKey: "cityName", latKey: "latitude", lonKey: "longitude"
        ) { return loc }

        // All failed — default
        return ("Неизвестно", nil, nil)
    }

    private func tryLocation(url: String, cityKey: String,
                              latKey: String, lonKey: String) async -> (String, Double?, Double?)? {
        guard let u = URL(string: url) else { return nil }
        do {
            let (data, _) = try await URLSession.shared.data(from: u)
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let city = json[cityKey] as? String else { return nil }
            let lat = json[latKey] as? Double
            let lon = json[lonKey] as? Double
            return (city, lat, lon)
        } catch {
            return nil
        }
    }

    @MainActor
    private func done(
        _ onComplete: @escaping (String, Bool, Double, String) -> Void,
        city: String, raining: Bool, temp: Double, desc: String
    ) {
        logLines.append("[i] \(city): \(raining ? "ДОЖДЬ ИДЁТ" : "ДОЖДЯ НЕТ") · \(desc) · \(String(format: "%.1f", temp))°C")
        onComplete(city, raining, temp, desc)
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
