// Wave.cs
using System;
using System.IO;
using System.Diagnostics;
using System.Runtime.InteropServices;

class WaveGenerator
{
    private float freq, amp, duration;
    private int sampleRate;
    private string waveType;
    private short[] samples;

    public WaveGenerator(float freq, float amp, float duration, int sampleRate, string waveType)
    {
        this.freq = freq;
        this.amp = amp;
        this.duration = duration;
        this.sampleRate = sampleRate;
        this.waveType = waveType;
        Generate();
    }

    private void Generate()
    {
        int numSamples = (int)(sampleRate * duration);
        samples = new short[numSamples];
        Random rand = new Random();
        for (int i = 0; i < numSamples; i++)
        {
            float t = (float)i / sampleRate;
            float phase = 2 * (float)Math.PI * freq * t;
            float val = 0;
            switch (waveType)
            {
                case "sine":
                    val = (float)Math.Sin(phase);
                    break;
                case "square":
                    val = (float)Math.Sin(phase) >= 0 ? 1 : -1;
                    break;
                case "sawtooth":
                    val = 2 * (phase / (2 * (float)Math.PI) - (float)Math.Floor(phase / (2 * (float)Math.PI) + 0.5f));
                    break;
                case "triangle":
                    val = 2 * (float)Math.Abs(2 * (phase / (2 * (float)Math.PI) - (float)Math.Floor(phase / (2 * (float)Math.PI) + 0.5f))) - 1;
                    break;
                case "noise":
                    val = (float)(rand.NextDouble() * 2 - 1);
                    break;
                default:
                    val = 0;
                    break;
            }
            samples[i] = (short)(amp * val * 32767);
        }
    }

    public void SaveWAV(string filename)
    {
        using var fs = new FileStream(filename, FileMode.Create);
        using var bw = new BinaryWriter(fs);
        int dataSize = samples.Length * 2;
        int byteRate = sampleRate * 2;
        // RIFF
        bw.Write(System.Text.Encoding.ASCII.GetBytes("RIFF"));
        bw.Write(36 + dataSize);
        bw.Write(System.Text.Encoding.ASCII.GetBytes("WAVE"));
        // fmt
        bw.Write(System.Text.Encoding.ASCII.GetBytes("fmt "));
        bw.Write(16);
        bw.Write((short)1);
        bw.Write((short)1);
        bw.Write(sampleRate);
        bw.Write(byteRate);
        bw.Write((short)2);
        bw.Write((short)16);
        // data
        bw.Write(System.Text.Encoding.ASCII.GetBytes("data"));
        bw.Write(dataSize);
        foreach (var s in samples)
        {
            bw.Write(s);
        }
    }

    public void Play(string filename)
    {
        try
        {
            if (RuntimeInformation.IsOSPlatform(OSPlatform.Windows))
                Process.Start("cmd", $"/c start {filename}");
            else if (RuntimeInformation.IsOSPlatform(OSPlatform.OSX))
                Process.Start("afplay", filename);
            else
            {
                string[] players = { "ffplay", "aplay", "mpg123" };
                bool started = false;
                foreach (var p in players)
                {
                    try
                    {
                        Process.Start(p, filename);
                        started = true;
                        break;
                    }
                    catch { }
                }
                if (!started) Console.WriteLine("No suitable audio player found.");
            }
        }
        catch (Exception e)
        {
            Console.WriteLine($"Playback error: {e.Message}");
        }
    }

    static void Main(string[] args)
    {
        if (args.Length > 0)
        {
            // Simple CLI parsing (could use System.CommandLine for better)
            var dict = new System.Collections.Generic.Dictionary<string, string>();
            for (int i = 0; i < args.Length; i++)
            {
                if (args[i].StartsWith("-") || args[i].StartsWith("--"))
                {
                    string key = args[i].TrimStart('-');
                    if (i + 1 < args.Length && !args[i + 1].StartsWith("-"))
                        dict[key] = args[++i];
                    else
                        dict[key] = "true";
                }
            }
            float freq = dict.ContainsKey("f") ? float.Parse(dict["f"]) : 440f;
            string wtype = dict.ContainsKey("t") ? dict["t"] : "sine";
            float amp = dict.ContainsKey("a") ? float.Parse(dict["a"]) : 0.8f;
            float dur = dict.ContainsKey("d") ? float.Parse(dict["d"]) : 2.0f;
            int rate = dict.ContainsKey("r") ? int.Parse(dict["r"]) : 44100;
            string output = dict.ContainsKey("o") ? dict["o"] : "output.wav";
            bool noPlay = dict.ContainsKey("no-play");
            var gen = new WaveGenerator(freq, amp, dur, rate, wtype);
            gen.SaveWAV(output);
            Console.WriteLine($"Saved to {output}");
            if (!noPlay) gen.Play(output);
        }
        else
        {
            Console.WriteLine("=== Waveform Audio Generator ===");
            Console.Write("Enter type (sine, square, sawtooth, triangle, noise, default: sine): ");
            string wtype = Console.ReadLine().Trim();
            if (string.IsNullOrEmpty(wtype)) wtype = "sine";
            Console.Write("Enter frequency (Hz, default: 440): ");
            float.TryParse(Console.ReadLine(), out float freq);
            if (freq <= 0) freq = 440;
            Console.Write("Enter amplitude (0.0-1.0, default: 0.8): ");
            float.TryParse(Console.ReadLine(), out float amp);
            if (amp < 0 || amp > 1) amp = 0.8f;
            Console.Write("Enter duration (seconds, default: 2.0): ");
            float.TryParse(Console.ReadLine(), out float dur);
            if (dur <= 0) dur = 2.0f;
            Console.Write("Enter sample rate (Hz, default: 44100): ");
            int.TryParse(Console.ReadLine(), out int rate);
            if (rate <= 0) rate = 44100;
            Console.Write("Enter output filename (default: output.wav): ");
            string fname = Console.ReadLine().Trim();
            if (string.IsNullOrEmpty(fname)) fname = "output.wav";
            if (!fname.EndsWith(".wav")) fname += ".wav";
            var gen = new WaveGenerator(freq, amp, dur, rate, wtype);
            gen.SaveWAV(fname);
            Console.WriteLine($"Saved to {fname}");
            Console.Write("Play? (y/n, default: y): ");
            string play = Console.ReadLine().Trim().ToLower();
            if (play != "n") gen.Play(fname);
        }
    }
}
