🌊 Waveform Audio Generator – Multi‑Language Edition

A versatile **audio waveform generator** that produces pure tones (sine, square, sawtooth, triangle) and saves them as WAV files, with optional system playback.  
Perfect for testing audio equipment, learning DSP, or creating sound samples.  
Built in **7 programming languages** – each with identical functionality.

## ✨ Features
- **Waveform types** – sine, square, sawtooth, triangle, white noise.
- **Customizable** – frequency (20‑20000 Hz), amplitude (0‑1), duration (seconds).
- **Sample rate** – adjustable (44100, 48000, 96000 Hz).
- **WAV export** – saves as 16‑bit PCM WAV file.
- **Playback** – automatically plays the generated sound using the system player.
- **Batch mode** – generate multiple files with different parameters.
- **Interactive CLI** – step‑by‑step prompts or command‑line arguments.

## 🗂 Languages & Files
| Language          | File          |
|-------------------|---------------|
| Python            | `wave.py`     |
| Go                | `wave.go`     |
| JavaScript (Node) | `wave.js`     |
| C#                | `Wave.cs`     |
| Java              | `Wave.java`   |
| Ruby              | `wave.rb`     |
| Swift             | `wave.swift`  |

## 🚀 How to Run
Each file is standalone – run it with the appropriate interpreter/compiler.

| Language | Command (interactive) | Command (CLI) |
|----------|----------------------|---------------|
| Python   | `python wave.py` | `python wave.py -f 440 -t sine -o output.wav` |
| Go       | `go run wave.go` | `go run wave.go -f 440 -t sine -o output.wav` |
| JavaScript | `node wave.js` | `node wave.js --freq 440 --type sine --output output.wav` |
| C#       | `dotnet run` | `dotnet run -- -f 440 -t sine -o output.wav` |
| Java     | `java Wave` | `java Wave -f 440 -t sine -o output.wav` |
| Ruby     | `ruby wave.rb` | `ruby wave.rb -f 440 -t sine -o output.wav` |
| Swift    | `swift wave.swift` | `swift wave.swift -f 440 -t sine -o output.wav` |

## 📊 Example Session
=== Waveform Audio Generator ===
Waveform types: sine, square, sawtooth, triangle, noise
Enter type (default: sine): sine
Enter frequency (Hz, default: 440): 440
Enter amplitude (0.0-1.0, default: 0.8): 0.8
Enter duration (seconds, default: 2.0): 2.0
Enter sample rate (Hz, default: 44100): 44100
Enter output filename (default: output.wav): sine_440.wav
Generating sine wave...
Saved to sine_440.wav
Playing...

text

## 🔧 Command‑Line Options (Common)
| Option | Description |
|--------|-------------|
| `-f, --freq` | Frequency in Hz (default: 440) |
| `-t, --type` | Waveform type: sine, square, sawtooth, triangle, noise |
| `-a, --amp` | Amplitude (0.0‑1.0, default: 0.8) |
| `-d, --dur` | Duration in seconds (default: 2.0) |
| `-r, --rate` | Sample rate (default: 44100) |
| `-o, --output` | Output WAV filename (default: output.wav) |
| `--play` | Play after generation (default: true) |

## 📁 WAV Format Details
- **Format**: PCM, 16‑bit, mono.
- **Chunk header**: standard RIFF WAV.
- **Data**: normalized to 16‑bit signed integers.

## 🤝 Contributing
Add support for stereo, envelopes, or effects (reverb, delay) – PRs welcome!

## 📜 License
MIT – use freely.
