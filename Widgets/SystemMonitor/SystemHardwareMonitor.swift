import CoreFoundation
import Darwin
import Foundation
import IOKit

/// Reads the CPU temperature shown in CPU Details through AppleSMC.
final class SystemHardwareMonitor {
    private let temperatureReader = AppleSMCTemperatureReader()

    func readTemperature() -> Double? {
        temperatureReader?.readCPU()
    }
}

private final class AppleSMCTemperatureReader {
    private typealias SMCBytes = (
        UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
        UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
        UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
        UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8
    )

    private struct SMCKeyData {
        struct Version {
            var major: UInt8 = 0
            var minor: UInt8 = 0
            var build: UInt8 = 0
            var reserved: UInt8 = 0
            var release: UInt16 = 0
        }

        struct PowerLimit {
            var version: UInt16 = 0
            var length: UInt16 = 0
            var cpu: UInt32 = 0
            var gpu: UInt32 = 0
            var memory: UInt32 = 0
        }

        struct KeyInfo {
            var dataSize: UInt32 = 0
            var dataType: UInt32 = 0
            var attributes: UInt8 = 0
        }

        var key: UInt32 = 0
        var version = Version()
        var powerLimit = PowerLimit()
        var keyInfo = KeyInfo()
        var padding: UInt16 = 0
        var result: UInt8 = 0
        var status: UInt8 = 0
        var data8: UInt8 = 0
        var data32: UInt32 = 0
        var bytes: SMCBytes = (
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0
        )
    }

    private var connection: io_connect_t = 0
    private let sensorKeys: [String]

    init?() {
        sensorKeys = Self.platformSensorKeys()

        var iterator: io_iterator_t = 0
        guard IOServiceGetMatchingServices(
            kIOMainPortDefault,
            IOServiceMatching("AppleSMC"),
            &iterator
        ) == kIOReturnSuccess else { return nil }
        defer { IOObjectRelease(iterator) }

        let service = IOIteratorNext(iterator)
        guard service != 0 else { return nil }
        defer { IOObjectRelease(service) }

        guard IOServiceOpen(service, mach_task_self_, 0, &connection) == kIOReturnSuccess else {
            return nil
        }
    }

    deinit {
        if connection != 0 {
            IOServiceClose(connection)
        }
    }

    func readCPU() -> Double? {
        for key in ["TC0D", "TC0E", "TC0F", "TC0P", "TC0H"] {
            if let value = value(for: key), Self.isSaneTemperature(value) {
                return value
            }
        }

        let values = sensorKeys.compactMap { key -> Double? in
            guard let value = value(for: key), Self.isSaneTemperature(value) else { return nil }
            return value
        }
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / Double(values.count)
    }

    private func value(for key: String) -> Double? {
        guard key.utf8.count == 4 else { return nil }

        var input = SMCKeyData()
        var output = SMCKeyData()
        input.key = Self.fourCharacterCode(key)
        input.data8 = 9 // readKeyInfo

        guard call(input: &input, output: &output) == kIOReturnSuccess,
              output.keyInfo.dataSize > 0
        else { return nil }

        let dataSize = Int(output.keyInfo.dataSize)
        let dataType = Self.string(from: output.keyInfo.dataType)

        input = SMCKeyData()
        input.key = Self.fourCharacterCode(key)
        input.keyInfo.dataSize = output.keyInfo.dataSize
        input.data8 = 5 // readBytes
        output = SMCKeyData()

        guard call(input: &input, output: &output) == kIOReturnSuccess else { return nil }

        let bytes = withUnsafeBytes(of: output.bytes) { rawBuffer in
            Array(rawBuffer.prefix(min(dataSize, rawBuffer.count)))
        }
        guard bytes.contains(where: { $0 != 0 }) else { return nil }

        switch dataType {
        case "flt ":
            guard bytes.count >= 4 else { return nil }
            var value: Float = 0
            withUnsafeMutableBytes(of: &value) { destination in
                destination.copyBytes(from: bytes.prefix(4))
            }
            return Double(value)
        case "sp78":
            guard bytes.count >= 2 else { return nil }
            let raw = Int16(bitPattern: UInt16(bytes[0]) << 8 | UInt16(bytes[1]))
            return Double(raw) / 256
        case "fpe2":
            guard bytes.count >= 2 else { return nil }
            return Double((Int(bytes[0]) << 6) | (Int(bytes[1]) >> 2))
        case "ui8 ":
            return Double(bytes[0])
        case "ui16":
            guard bytes.count >= 2 else { return nil }
            return Double(UInt16(bytes[0]) << 8 | UInt16(bytes[1]))
        default:
            return nil
        }
    }

    private func call(input: inout SMCKeyData, output: inout SMCKeyData) -> kern_return_t {
        var outputSize = MemoryLayout<SMCKeyData>.stride
        return IOConnectCallStructMethod(
            connection,
            2,
            &input,
            MemoryLayout<SMCKeyData>.stride,
            &output,
            &outputSize
        )
    }

    private static func platformSensorKeys() -> [String] {
        let name = cpuBrandString()
        if name.contains("M5") {
            return [
                "Tp00", "Tp04", "Tp08", "Tp0C", "Tp0G", "Tp0K",
                "Tp0O", "Tp0R", "Tp0U", "Tp0X", "Tp0a", "Tp0d",
                "Tp0g", "Tp0j", "Tp0m", "Tp0p", "Tp0u", "Tp0y",
            ]
        }
        if name.contains("M4") {
            return [
                "Te05", "Te09", "Te0H", "Te0S", "Tp01", "Tp05",
                "Tp09", "Tp0D", "Tp0V", "Tp0Y", "Tp0b", "Tp0e",
            ]
        }
        if name.contains("M3") {
            return [
                "Te05", "Te0L", "Te0P", "Te0S", "Tf04", "Tf09",
                "Tf0A", "Tf0B", "Tf0D", "Tf0E", "Tf44", "Tf49",
                "Tf4A", "Tf4B", "Tf4D", "Tf4E",
            ]
        }
        if name.contains("M2") {
            return [
                "Tp1h", "Tp1t", "Tp1p", "Tp1l", "Tp01", "Tp05",
                "Tp09", "Tp0D", "Tp0X", "Tp0b", "Tp0f", "Tp0j",
            ]
        }
        if name.contains("M1") {
            return [
                "Tp09", "Tp0T", "Tp01", "Tp05", "Tp0D", "Tp0H",
                "Tp0L", "Tp0P", "Tp0X", "Tp0b",
            ]
        }
        return []
    }

    fileprivate static func cpuBrandString() -> String {
        var size = 0
        guard sysctlbyname("machdep.cpu.brand_string", nil, &size, nil, 0) == 0, size > 0 else {
            return ""
        }
        var buffer = [CChar](repeating: 0, count: size)
        guard sysctlbyname("machdep.cpu.brand_string", &buffer, &size, nil, 0) == 0 else {
            return ""
        }
        return String(cString: buffer)
    }

    private static func isSaneTemperature(_ value: Double) -> Bool {
        value.isFinite && value > 0 && value < 110
    }

    private static func fourCharacterCode(_ string: String) -> UInt32 {
        string.utf8.reduce(0) { ($0 << 8) | UInt32($1) }
    }

    private static func string(from code: UInt32) -> String {
        String(bytes: [
            UInt8((code >> 24) & 0xff),
            UInt8((code >> 16) & 0xff),
            UInt8((code >> 8) & 0xff),
            UInt8(code & 0xff),
        ], encoding: .ascii) ?? ""
    }
}
