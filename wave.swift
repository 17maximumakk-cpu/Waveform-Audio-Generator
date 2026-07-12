// wave.swift
import Foundation

class WaveGenerator {
    let freq: Float
    let amp: Float
    let duration: Float
    let sampleRate: Int
    let waveType: String
    var samples: [Int16] = []

    init(freq: Float = 440, amp: Float = 0.8, duration: Float = 2.0, sampleRate: Int = 44100, waveType: String = "sine") {
        self.freq = freq
        self.amp = amp
        self.duration = duration
        self.sampleRate = sampleRate
        self.waveType = waveType
        generate()
    }

    func generate() {
        let numSamples = Int(Float(sampleRate) * duration)
        for i in 0..<numSamples {
            let t = Float(i) / Float(sampleRate)
            let phase = 2 * Float.pi * freq * t
            var val: Float = 0
            switch waveType {
            case "sine":
                val = sin(phase)
            case "square":
                val = sin(phase) >= 0 ? 1 : -1
            case "sawtooth":
                val = 2 * (phase / (2 * Float.pi) - floor(phase / (2 * Float.pi) + 0.5))
            case "triangle":
                val = 2 * abs(2 * (phase / (2 * Float.pi) - floor(phase / (2 * Float.pi) + 0.5))) - 1
            case "noise":
                val = Float.random(in: -1...1)
            default:
                val = 0
            }
            samples.append(Int16(amp * val * 32767))
        }
    }

    func saveWAV(filename: String) throws {
        let dataSize = samples.count * 2
        let byteRate = sampleRate * 2
        let headerSize = 44
        let fileSize = headerSize + dataSize
        var buffer = Data(capacity: fileSize)
        // RIFF
        buffer.append("RIFF".data(using: .utf8)!)
        buffer.append(withUnsafeBytes(of: UInt32(36 + dataSize).littleEndian) { Data($0) })
        buffer.append("WAVE".data(using: .utf8)!)
        // fmt
        buffer.append("fmt ".data(using: .utf8)!)
        buffer.append(withUnsafeBytes(of: UInt32(16).littleEndian) { Data($0) })
        buffer.append(withUnsafeBytes(of: UInt16(1).littleEndian) { Data($0) })
        buffer.append(withUnsafeBytes(of: UInt16(1).littleEndian) { Data($0) })
        buffer.append(withUnsafeBytes(of: UInt32(sampleRate).littleEndian) { Data($0) })
        buffer.append(withUnsafeBytes(of: UInt32(byteRate).littleEndian) { Data($0) })
        buffer.append(withUnsafeBytes(of: UInt16(2).littleEndian) { Data($0) })
        buffer.append(withUnsafeBytes(of: UInt16(16).littleEndian) { Data($0) })
        // data
        buffer.append("data".data(using: .utf8)!)
        buffer.append(withUnsafeBytes(of: UInt32(dataSize).littleEndian) { Data($0) })
        // samples
        for s in samples {
            buffer.append(withUnsafeBytes(of: s.littleEndian) { Data($0) })
        }
        try buffer.write(to: URL(fileURLWithPath: filename))
    }

    func play(filename: String) {
        #if os(macOS)
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/afplay")
        process.arguments = [filename]
        try? process.run()
        #elseif os(Linux)
        let players = ["ffplay", "aplay", "mpg123"]
        var started = false
        for p in players {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
            process.arguments = [p]
            let pipe = Pipe()
            process.standardOutput = pipe
            try? process.run()
            process.waitUntilExit()
            if process.terminationStatus == 0 {
                let playProcess = Process()
                playProcess.executableURL = URL(fileURLWithPath: "/usr/bin/env")
                playProcess.arguments = [p, filename]
                try? playProcess.run()
                started = true
                break
            }
        }
        if !started {
            print("No suitable audio player found.")
        }
        #elseif os(Windows)
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "C:/Windows/System32/cmd.exe")
        process.arguments = ["/c", "start", filename]
        try? process.run()
        #endif
    }
}

func interactive() {
    print("=== Waveform Audio Generator ===")
    let types = ["sine", "square", "sawtooth", "triangle", "noise"]
    print("Enter type (\(types.joined(separator: ", ")), default: sine): ", terminator: "")
    var wtype = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "sine"
    if !types.contains(wtype) { wtype = "sine" }
    print("Enter frequency (Hz, default: 440): ", terminator: "")
    let freq = Float(readLine() ?? "") ?? 440
    print("Enter amplitude (0.0-1.0, default: 0.8): ", terminator: "")
    let amp = Float(readLine() ?? "") ?? 0.8
    print("Enter duration (seconds, default: 2.0): ", terminator: "")
    let dur = Float(readLine() ?? "") ?? 2.0
    print("Enter sample rate (Hz, default: 44100): ", terminator: "")
    let rate = Int(readLine() ?? "") ?? 44100
    print("Enter output filename (default: output.wav): ", terminator: "")
    var fname = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "output.wav"
    if !fname.hasSuffix(".wav") { fname += ".wav" }
    let gen = WaveGenerator(freq: freq, amp: amp, duration: dur, sampleRate: rate, waveType: wtype)
    do {
        try gen.saveWAV(filename: fname)
        print("Saved to \(fname)")
        print("Play? (y/n, default: y): ", terminator: "")
        let play = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? "y"
        if play != "n" { gen.play(filename: fname) }
    } catch {
        print("Error saving: \(error)")
    }
}

func cli() {
    let args = CommandLine.arguments.dropFirst()
    var params: [String: String] = [:]
    var i = 0
    while i < args.count {
        let arg = args[i]
        if arg.hasPrefix("-") || arg.hasPrefix("--") {
            let key = arg.replacingOccurrences(of: "-", with: "")
            if i+1 < args.count && !args[i+1].hasPrefix("-") {
                params[key] = args[i+1]
                i += 2
            } else {
                params[key] = "true"
                i += 1
            }
        } else {
            i += 1
        }
    }
    let freq = Float(params["f"] ?? params["freq"] ?? "440") ?? 440
    let wtype = params["t"] ?? params["type"] ?? "sine"
    let amp = Float(params["a"] ?? params["amp"] ?? "0.8") ?? 0.8
    let dur = Float(params["d"] ?? params["dur"] ?? "2.0") ?? 2.0
    let rate = Int(params["r"] ?? params["rate"] ?? "44100") ?? 44100
    let output = params["o"] ?? params["output"] ?? "output.wav"
    let noPlay = params["no-play"] != nil
    let gen = WaveGenerator(freq: freq, amp: amp, duration: dur, sampleRate: rate, waveType: wtype)
    do {
        try gen.saveWAV(filename: output)
        print("Saved to \(output)")
        if !noPlay { gen.play(filename: output) }
    } catch {
        print("Error saving: \(error)")
    }
}

if CommandLine.arguments.count > 1 {
    cli()
} else {
    interactive()
}
