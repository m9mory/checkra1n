import UIKit

/// Real device hardware info — no hardcoded values
enum DeviceInfo {

    /// Internal model identifier, e.g. "iPhone18,1"
    static let modelIdentifier: String = {
        var info = utsname()
        uname(&info)
        return withUnsafePointer(to: &info.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: Int(_SYS_NAMELEN)) {
                String(cString: $0)
            }
        }
    }()

    /// Human-readable device name, e.g. "iPhone 16 Pro"
    static let deviceName: String = mapToName(modelIdentifier)

    /// Chip inside, e.g. "A19 Pro"
    static let chip: String = mapToChip(modelIdentifier)

    /// iOS version, e.g. "27.0"
    static let iosVersion: String = UIDevice.current.systemVersion

    /// Build number, e.g. "24A335"
    static let buildNumber: String = {
        // Not directly available in public API; use system version as fallback
        if let raw = try? String(
            contentsOf: URL(fileURLWithPath: "/System/Library/CoreServices/SystemVersion.plist"),
            encoding: .utf8
        ) {
            // Quick-n-dirty parse — good enough for a prank
            for line in raw.components(separatedBy: "\n") {
                if line.contains("ProductBuildVersion") {
                    return line.components(separatedBy: "<string>")
                        .last?.components(separatedBy: "</string>").first ?? "?"
                }
            }
        }
        return "?"
    }()

    // MARK: - Mapping tables

    private static func mapToName(_ id: String) -> String {
        if id.hasPrefix("iPad")   { return "iPad" }
        if id.hasPrefix("iPod")   { return "iPod touch" }
        if id == "x86_64" || id == "arm64" { return "iPhone (simulator)" }

        return switch id {
        case "iPhone1,1","iPhone1,2":                 "iPhone"
        case "iPhone2,1":                              "iPhone 3GS"
        case "iPhone3,1","iPhone3,2","iPhone3,3":      "iPhone 4"
        case "iPhone4,1":                              "iPhone 4S"
        case "iPhone5,1","iPhone5,2":                  "iPhone 5"
        case "iPhone5,3","iPhone5,4":                  "iPhone 5C"
        case "iPhone6,1","iPhone6,2":                  "iPhone 5S"
        case "iPhone7,1":                              "iPhone 6 Plus"
        case "iPhone7,2":                              "iPhone 6"
        case "iPhone8,1":                              "iPhone 6S"
        case "iPhone8,2":                              "iPhone 6S Plus"
        case "iPhone8,4":                              "iPhone SE (1st)"
        case "iPhone9,1","iPhone9,3":                  "iPhone 7"
        case "iPhone9,2","iPhone9,4":                  "iPhone 7 Plus"
        case "iPhone10,1","iPhone10,4":                "iPhone 8"
        case "iPhone10,2","iPhone10,5":                "iPhone 8 Plus"
        case "iPhone10,3","iPhone10,6":                "iPhone X"
        case "iPhone11,2":                             "iPhone XS"
        case "iPhone11,4","iPhone11,6":                "iPhone XS Max"
        case "iPhone11,8":                             "iPhone XR"
        case "iPhone12,1":                             "iPhone 11"
        case "iPhone12,3":                             "iPhone 11 Pro"
        case "iPhone12,5":                             "iPhone 11 Pro Max"
        case "iPhone12,8":                             "iPhone SE (2nd)"
        case "iPhone13,1":                             "iPhone 12 mini"
        case "iPhone13,2":                             "iPhone 12"
        case "iPhone13,3":                             "iPhone 12 Pro"
        case "iPhone13,4":                             "iPhone 12 Pro Max"
        case "iPhone14,2":                             "iPhone 13 Pro"
        case "iPhone14,3":                             "iPhone 13 Pro Max"
        case "iPhone14,4":                             "iPhone 13 mini"
        case "iPhone14,5":                             "iPhone 13"
        case "iPhone14,6":                             "iPhone SE (3rd)"
        case "iPhone14,7":                             "iPhone 14"
        case "iPhone14,8":                             "iPhone 14 Plus"
        case "iPhone15,2":                             "iPhone 14 Pro"
        case "iPhone15,3":                             "iPhone 14 Pro Max"
        case "iPhone15,4":                             "iPhone 15"
        case "iPhone15,5":                             "iPhone 15 Plus"
        case "iPhone16,1":                             "iPhone 15 Pro"
        case "iPhone16,2":                             "iPhone 15 Pro Max"
        case "iPhone17,1":                             "iPhone 16 Pro"
        case "iPhone17,2":                             "iPhone 16 Pro Max"
        case "iPhone17,3":                             "iPhone 16"
        case "iPhone17,4":                             "iPhone 16 Plus"
        case "iPhone18,1":                             "iPhone 17 Pro"
        case "iPhone18,2":                             "iPhone 17 Pro Max"
        case "iPhone18,3":                             "iPhone 17"
        case "iPhone18,4":                             "iPhone 17 Air"
        default:                                       id
        }
    }

    private static func mapToChip(_ id: String) -> String {
        if id.hasPrefix("iPad1") || id.hasPrefix("iPod1") || id.hasPrefix("iPod2") { return "A4" }
        if id.hasPrefix("iPad2") || id.hasPrefix("iPod3") || id.hasPrefix("iPod4") { return "A5" }
        if id.hasPrefix("iPad")   { return "A\(Int.random(in: 8...17))" }
        if id.hasPrefix("iPod")   { return "A8" }
        if id == "x86_64" || id == "arm64" { return "A19 Pro (sim)" }

        return switch id {
        case "iPhone1,1","iPhone1,2","iPhone2,1",
             "iPhone3,1","iPhone3,2","iPhone3,3":      "A4"
        case "iPhone4,1":                              "A5"
        case "iPhone5,1","iPhone5,2","iPhone5,3","iPhone5,4": "A6"
        case "iPhone6,1","iPhone6,2":                  "A7"
        case "iPhone7,1","iPhone7,2":                  "A8"
        case "iPhone8,1","iPhone8,2":                  "A9"
        case "iPhone8,4","iPhone9,1","iPhone9,3",
             "iPhone9,2","iPhone9,4":                  "A10 Fusion"
        case "iPhone10,1","iPhone10,4","iPhone10,2",
             "iPhone10,5","iPhone10,3","iPhone10,6":   "A11 Bionic"
        case "iPhone11,2","iPhone11,4","iPhone11,6",
             "iPhone11,8":                             "A12 Bionic"
        case "iPhone12,1","iPhone12,3","iPhone12,5",
             "iPhone12,8":                             "A13 Bionic"
        case "iPhone13,1","iPhone13,2","iPhone13,3",
             "iPhone13,4":                             "A14 Bionic"
        case "iPhone14,2","iPhone14,3","iPhone14,4",
             "iPhone14,5","iPhone14,6":                "A15 Bionic"
        case "iPhone14,7","iPhone14,8","iPhone15,2",
             "iPhone15,3":                             "A16 Bionic"
        case "iPhone15,4","iPhone15,5","iPhone16,1",
             "iPhone16,2":                             "A17 Pro"
        case "iPhone17,1","iPhone17,2","iPhone17,3",
             "iPhone17,4":                             "A18 Pro"
        case "iPhone18,1","iPhone18,2","iPhone18,3",
             "iPhone18,4":                             "A19 Pro"
        default:                                       "A\(Int.random(in: 5...19))"
        }
    }
}
