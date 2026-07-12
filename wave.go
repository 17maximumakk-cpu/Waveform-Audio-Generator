// wave.go
package main

import (
	"bufio"
	"flag"
	"fmt"
	"math"
	"os"
	"os/exec"
	"runtime"
	"strconv"
	"strings"
)

type WaveGenerator struct {
	freq       float64
	amp        float64
	duration   float64
	sampleRate int
	waveType   string
	samples    []int16
}

func NewWaveGenerator(freq, amp, duration float64, sampleRate int, waveType string) *WaveGenerator {
	w := &WaveGenerator{
		freq:       freq,
		amp:        amp,
		duration:   duration,
		sampleRate: sampleRate,
		waveType:   waveType,
	}
	w.generate()
	return w
}

func (w *WaveGenerator) generate() {
	numSamples := int(float64(w.sampleRate) * w.duration)
	w.samples = make([]int16, numSamples)
	for i := 0; i < numSamples; i++ {
		t := float64(i) / float64(w.sampleRate)
		phase := 2 * math.Pi * w.freq * t
		var val float64
		switch w.waveType {
		case "sine":
			val = math.Sin(phase)
		case "square":
			if math.Sin(phase) >= 0 {
				val = 1
			} else {
				val = -1
			}
		case "sawtooth":
			val = 2*(phase/(2*math.Pi)-math.Floor(phase/(2*math.Pi)+0.5))
		case "triangle":
			val = 2*math.Abs(2*(phase/(2*math.Pi)-math.Floor(phase/(2*math.Pi)+0.5))) - 1
		case "noise":
			val = randomFloat(-1, 1)
		default:
			val = 0
		}
		w.samples[i] = int16(w.amp * val * 32767)
	}
}

func randomFloat(min, max float64) float64 {
	return min + (max-min)*float64(rand.Intn(1000000))/1000000.0
}

func (w *WaveGenerator) saveWAV(filename string) error {
	file, err := os.Create(filename)
	if err != nil {
		return err
	}
	defer file.Close()
	// WAV header: 44 bytes
	dataSize := len(w.samples) * 2
	byteRate := w.sampleRate * 2
	// RIFF header
	file.WriteString("RIFF")
	writeUint32(file, uint32(36+dataSize))
	file.WriteString("WAVE")
	// fmt chunk
	file.WriteString("fmt ")
	writeUint32(file, 16)
	writeUint16(file, 1) // PCM
	writeUint16(file, 1) // mono
	writeUint32(file, uint32(w.sampleRate))
	writeUint32(file, uint32(byteRate))
	writeUint16(file, 2) // block align
	writeUint16(file, 16) // bits per sample
	// data chunk
	file.WriteString("data")
	writeUint32(file, uint32(dataSize))
	// samples
	for _, s := range w.samples {
		writeInt16(file, s)
	}
	return nil
}

func writeUint32(f *os.File, v uint32) {
	b := []byte{byte(v), byte(v >> 8), byte(v >> 16), byte(v >> 24)}
	f.Write(b)
}

func writeUint16(f *os.File, v uint16) {
	b := []byte{byte(v), byte(v >> 8)}
	f.Write(b)
}

func writeInt16(f *os.File, v int16) {
	u := uint16(v)
	f.Write([]byte{byte(u), byte(u >> 8)})
}

func (w *WaveGenerator) play(filename string) {
	var cmd *exec.Cmd
	switch runtime.GOOS {
	case "windows":
		cmd = exec.Command("cmd", "/c", "start", filename)
	case "darwin":
		cmd = exec.Command("afplay", filename)
	default:
		// Try ffplay, aplay, mpg123
		players := []string{"ffplay", "aplay", "mpg123"}
		for _, p := range players {
			if _, err := exec.LookPath(p); err == nil {
				cmd = exec.Command(p, filename)
				break
			}
		}
	}
	if cmd != nil {
		cmd.Run()
	}
}

func interactive() {
	reader := bufio.NewReader(os.Stdin)
	fmt.Println("=== Waveform Audio Generator ===")
	types := []string{"sine", "square", "sawtooth", "triangle", "noise"}
	fmt.Printf("Waveform types: %s\n", strings.Join(types, ", "))
	fmt.Print("Enter type (default: sine): ")
	wtype, _ := reader.ReadString('\n')
	wtype = strings.TrimSpace(wtype)
	if wtype == "" {
		wtype = "sine"
	}
	fmt.Print("Enter frequency (Hz, default: 440): ")
	freqStr, _ := reader.ReadString('\n')
	freq := 440.0
	if f, err := strconv.ParseFloat(strings.TrimSpace(freqStr), 64); err == nil && f > 0 {
		freq = f
	}
	fmt.Print("Enter amplitude (0.0-1.0, default: 0.8): ")
	ampStr, _ := reader.ReadString('\n')
	amp := 0.8
	if a, err := strconv.ParseFloat(strings.TrimSpace(ampStr), 64); err == nil && a >= 0 && a <= 1 {
		amp = a
	}
	fmt.Print("Enter duration (seconds, default: 2.0): ")
	durStr, _ := reader.ReadString('\n')
	dur := 2.0
	if d, err := strconv.ParseFloat(strings.TrimSpace(durStr), 64); err == nil && d > 0 {
		dur = d
	}
	fmt.Print("Enter sample rate (Hz, default: 44100): ")
	rateStr, _ := reader.ReadString('\n')
	rate := 44100
	if r, err := strconv.Atoi(strings.TrimSpace(rateStr)); err == nil && r > 0 {
		rate = r
	}
	fmt.Print("Enter output filename (default: output.wav): ")
	fname, _ := reader.ReadString('\n')
	fname = strings.TrimSpace(fname)
	if fname == "" {
		fname = "output.wav"
	}
	if !strings.HasSuffix(fname, ".wav") {
		fname += ".wav"
	}
	gen := NewWaveGenerator(freq, amp, dur, rate, wtype)
	if err := gen.saveWAV(fname); err != nil {
		fmt.Println("Error saving:", err)
		return
	}
	fmt.Printf("Saved to %s\n", fname)
	fmt.Print("Play? (y/n, default: y): ")
	play, _ := reader.ReadString('\n')
	if strings.ToLower(strings.TrimSpace(play)) != "n" {
		gen.play(fname)
	}
}

func cli() {
	freq := flag.Float64("f", 440, "Frequency in Hz")
	wtype := flag.String("t", "sine", "Waveform type (sine, square, sawtooth, triangle, noise)")
	amp := flag.Float64("a", 0.8, "Amplitude (0.0-1.0)")
	dur := flag.Float64("d", 2.0, "Duration in seconds")
	rate := flag.Int("r", 44100, "Sample rate")
	output := flag.String("o", "output.wav", "Output filename")
	noPlay := flag.Bool("no-play", false, "Don't play after generation")
	flag.Parse()
	gen := NewWaveGenerator(*freq, *amp, *dur, *rate, *wtype)
	if err := gen.saveWAV(*output); err != nil {
		fmt.Println("Error saving:", err)
		return
	}
	fmt.Printf("Saved to %s\n", *output)
	if !*noPlay {
		gen.play(*output)
	}
}

func main() {
	if len(os.Args) > 1 {
		cli()
	} else {
		interactive()
	}
}
