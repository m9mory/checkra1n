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

        let dev = DeviceInfo.self

        let bootLogs: [String] = [
            "[*] checkra1n 0.13.3 beta — \"odyssey edition\"",
            "[*] Initializing exploit environment...",
            "[*] Device: \(dev.modelIdentifier) (\(dev.chip))",
            "[*] Model: \(dev.deviceName)",
            "[*] iOS version: \(dev.iosVersion) (\(dev.buildNumber))",
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
            "[*] Exploiting checkm8 (\(dev.chip), t8140)...",
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
            "[✓] Jailbreak complete!",
        ]

        var delay: Double = 0

        // Boot
        for log in bootLogs {
            schedule(delay: delay) { self.logLines.append(log) }
            delay += log.isEmpty ? 0.02 : 0.05
        }

        // Modules
        for mod in modules {
            schedule(delay: delay) { self.logLines.append("[+] Loading \(mod)...") }
            delay += Double.random(in: 0.02...0.05)
            schedule(delay: delay) { self.logLines.append("[✓] \(mod) OK") }
            delay += Double.random(in: 0.01...0.03)
        }

        // Exploit
        for log in exploitChain {
            schedule(delay: delay) { self.logLines.append(log) }
            delay += log.isEmpty ? 0.02 : 0.06
        }

        // Random progress
        for _ in 0..<55 {
            let log = randomProgressLog()
            schedule(delay: delay) { self.logLines.append(log) }
            delay += Double.random(in: 0.01...0.04)
        }

        // Late
        for log in lateLogs {
            schedule(delay: delay) { self.logLines.append(log) }
            delay += log.isEmpty ? 0.02 : 0.06
        }

        // Wait for logs to finish displaying, then fetch weather + call onComplete
        schedule(delay: delay + 0.5) {
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
            "Patching kernel... 18%",
            "Patching kernel... 34%",
            "Patching kernel... 47%",
            "Patching kernel... 61%",
            "Patching kernel... 73%",
            "Patching kernel... 85%",
            "Patching kernel... 92%",
            "Patching kernel... 100%",
            "Kernel slide: 0x00000000028dc000",
            "Kernel base: 0xfffffff007604000",
            "Allocated trampoline at 0xfffffff008340000",
            "Trampoline page remapped R/W/X",
            "Virtual memory region: 0xfffffff008300000–0xfffffff0083fffff",
            "Restoring virtual memory map...",
            "Setting nonce generator...",
            "APTicket verified successfully",
            "Boot nonce set: 0xdeadbeefcafebabe",
            "iBoot patchset #3 applied",
            "AMFI: cs_enforcement_disable = 1",
            "AMFI: PE_i_can_has_debugger = 1",
            "Sandbox hook installed @ 0xfffffff00978a000",
            "Sandbox: MACF policy #2 relaxed",
            "Signature check bypassed (AMFI patch)",
            "Mounting /dev/disk0s1s1 as /private/var",
            "Remounting rootfs as r/w...",
            "TF_PLATFORM flag set on /Applications",
            "Copying trust cache...",
            "Trust cache: 247 hashes injected",
            "Hooking sysent table (n=768)...",
            "Installing bootstrap packages...",
            "Cydia repo: https://apt.bingner.com",
            "Cydia repo: https://repo.chariz.com",
            "Sileo: registered 7 package sources",
            "Running uicache --all --respring",
            "libhooker: 14 tweak dylibs loaded",
            "Injecting payload into launchd (pid 1)...",
            "Cleaning up kernel state...",
            "panic(cpu 2 caller 0xfffffff008a1b4c0): \"double fault\" — recovered",
            "SIGBUS at 0xfffff0008370 — signal handled",
            "SIGILL  at 0xfffffff0077000a8 — recovered",
            "Kernel trap #14 (page fault) — expected, skipping",
            "AppleKeyStore: locked — unlocking...",
            "SEP firmware: SEPOS 2024.08 (patched)",
            "iBoot-9239.140.4 — nonce set OK",
            "Restoring host TCP stack...",
            "USB serial: CPID:0x8960 CPRV:0x11 CPFM:0x03",
            "IOAESAccelerator: hardware AES ready",
            "[?] Unknown symbol — patching trampoline...",
        ].randomElement()!
    }

    // MARK: - Networking (same as before)

    private func fetchWeatherInfo(
        onComplete: @escaping (_ city: String, _ isRaining: Bool,
                               _ temp: Double, _ desc: String) -> Void
    ) {
        Task {
            let (city, lat, lon) = await fetchLocation()
            guard let lat, let lon else {
                await done(onComplete, city: city, raining: false, temp: 0, desc: "Нет данных")
                return
            }
            do {
                let url = URL(string:
                    "https://api.open-meteo.com/v1/forecast?latitude=\(lat)&longitude=\(lon)&current_weather=true")!
                let (data, _) = try await URLSession.shared.data(from: url)
                guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let cur = json["current_weather"] as? [String: Any],
                      let code = cur["weathercode"] as? Int,
                      let temp = cur["temperature"] as? Double else {
                    await done(onComplete, city: city, raining: false, temp: 0, desc: "Нет данных")
                    return
                }
                let raining = (51...99).contains(code)
                await done(onComplete, city: city, raining: raining,
                           temp: temp, desc: weatherDesc(code))
            } catch {
                await done(onComplete, city: city, raining: false,
                           temp: 0, desc: error.localizedDescription)
            }
        }
    }

    private func fetchLocation() async -> (String, Double?, Double?) {
        if let r = await tryLoc(url: "http://ip-api.com/json/?fields=city,lat,lon",
                                 ck: "city", latk: "lat", lonk: "lon") { return r }
        if let r = await tryLoc(url: "https://ipwho.is/json",
                                 ck: "city", latk: "latitude", lonk: "longitude") { return r }
        if let r = await tryLoc(url: "https://freeipapi.com/api/json",
                                 ck: "cityName", latk: "latitude", lonk: "longitude") { return r }
        return ("Неизвестно", nil, nil)
    }

    private func tryLoc(url: String, ck: String,
                         latk: String, lonk: String) async -> (String, Double?, Double?)? {
        guard let u = URL(string: url) else { return nil }
        do {
            let (data, _) = try await URLSession.shared.data(from: u)
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let city = json[ck] as? String else { return nil }
            return (city, json[latk] as? Double, json[lonk] as? Double)
        } catch { return nil }
    }

    @MainActor
    private func done(_ cb: @escaping (String, Bool, Double, String) -> Void,
                      city: String, raining: Bool, temp: Double, desc: String) {
        onComplete(cb, city: city, raining: raining, temp: temp, desc: desc)
    }

    private func onComplete(_ cb: @escaping (String, Bool, Double, String) -> Void,
                            city: String, raining: Bool, temp: Double, desc: String) {
        cb(city, raining, temp, desc)
    }

    private func weatherDesc(_ code: Int) -> String {
        switch code {
        case 0:  "Ясно";        case 1,2,3: "Облачно"
        case 45,48: "Туман";    case 51,53,55: "Морось"
        case 61,63,65: "Дождь"; case 66,67: "Ледяной дождь"
        case 71,73,75: "Снег";  case 77: "Град"
        case 80,81,82: "Ливень"; case 85,86: "Снегопад"
        case 95: "Гроза";       case 96,99: "Гроза с градом"
        default: "Неизвестно"
        }
    }
}
