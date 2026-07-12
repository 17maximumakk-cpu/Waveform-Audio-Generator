// Wave.java
import java.io.*;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.util.Random;

public class Wave {
    private float freq, amp, duration;
    private int sampleRate;
    private String waveType;
    private short[] samples;
    private Random rand = new Random();

    public Wave(float freq, float amp, float duration, int sampleRate, String waveType) {
        this.freq = freq;
        this.amp = amp;
        this.duration = duration;
        this.sampleRate = sampleRate;
        this.waveType = waveType;
        generate();
    }

    private void generate() {
        int numSamples = (int)(sampleRate * duration);
        samples = new short[numSamples];
        for (int i = 0; i < numSamples; i++) {
            float t = (float)i / sampleRate;
            float phase = 2 * (float)Math.PI * freq * t;
            float val = 0;
            switch (waveType) {
                case "sine":
                    val = (float)Math.sin(phase);
                    break;
                case "square":
                    val = Math.sin(phase) >= 0 ? 1 : -1;
                    break;
                case "sawtooth":
                    val = 2 * (phase / (2 * (float)Math.PI) - (float)Math.floor(phase / (2 * (float)Math.PI) + 0.5));
                    break;
                case "triangle":
                    val = 2 * (float)Math.abs(2 * (phase / (2 * (float)Math.PI) - (float)Math.floor(phase / (2 * (float)Math.PI) + 0.5))) - 1;
                    break;
                case "noise":
                    val = (float)(rand.nextDouble() * 2 - 1);
                    break;
                default:
                    val = 0;
            }
            samples[i] = (short)(amp * val * 32767);
        }
    }

    public void saveWAV(String filename) throws IOException {
        try (FileOutputStream fos = new FileOutputStream(filename);
             DataOutputStream dos = new DataOutputStream(fos)) {
            int dataSize = samples.length * 2;
            int byteRate = sampleRate * 2;
            // RIFF
            dos.writeBytes("RIFF");
            dos.writeInt(ByteBuffer.allocate(4).order(ByteOrder.LITTLE_ENDIAN).putInt(36 + dataSize).array());
            dos.writeBytes("WAVE");
            // fmt
            dos.writeBytes("fmt ");
            dos.writeInt(16);
            dos.writeShort(1);
            dos.writeShort(1);
            dos.writeInt(sampleRate);
            dos.writeInt(byteRate);
            dos.writeShort(2);
            dos.writeShort(16);
            // data
            dos.writeBytes("data");
            dos.writeInt(dataSize);
            for (short s : samples) {
                dos.writeShort(s);
            }
        }
    }

    public void play(String filename) {
        String os = System.getProperty("os.name").toLowerCase();
        try {
            if (os.contains("win")) {
                Runtime.getRuntime().exec(new String[]{"cmd", "/c", "start", filename});
            } else if (os.contains("mac")) {
                Runtime.getRuntime().exec(new String[]{"afplay", filename});
            } else {
                String[] players = {"ffplay", "aplay", "mpg123"};
                for (String p : players) {
                    try {
                        Runtime.getRuntime().exec(new String[]{p, filename});
                        return;
                    } catch (IOException e) {}
                }
                System.out.println("No suitable audio player found.");
            }
        } catch (Exception e) {
            System.out.println("Playback error: " + e.getMessage());
        }
    }

    public static void main(String[] args) throws IOException {
        if (args.length > 0) {
            // Simple CLI
            java.util.Map<String, String> params = new java.util.HashMap<>();
            for (int i = 0; i < args.length; i++) {
                if (args[i].startsWith("-") || args[i].startsWith("--")) {
                    String key = args[i].replaceFirst("^-+", "");
                    if (i + 1 < args.length && !args[i + 1].startsWith("-")) {
                        params.put(key, args[++i]);
                    } else {
                        params.put(key, "true");
                    }
                }
            }
            float freq = params.containsKey("f") ? Float.parseFloat(params.get("f")) : 440f;
            String wtype = params.getOrDefault("t", "sine");
            float amp = params.containsKey("a") ? Float.parseFloat(params.get("a")) : 0.8f;
            float dur = params.containsKey("d") ? Float.parseFloat(params.get("d")) : 2.0f;
            int rate = params.containsKey("r") ? Integer.parseInt(params.get("r")) : 44100;
            String output = params.getOrDefault("o", "output.wav");
            boolean noPlay = params.containsKey("no-play");
            Wave gen = new Wave(freq, amp, dur, rate, wtype);
            gen.saveWAV(output);
            System.out.println("Saved to " + output);
            if (!noPlay) gen.play(output);
        } else {
            BufferedReader reader = new BufferedReader(new InputStreamReader(System.in));
            System.out.println("=== Waveform Audio Generator ===");
            System.out.print("Enter type (sine, square, sawtooth, triangle, noise, default: sine): ");
            String wtype = reader.readLine().trim();
            if (wtype.isEmpty()) wtype = "sine";
            System.out.print("Enter frequency (Hz, default: 440): ");
            float freq = 440f;
            try { freq = Float.parseFloat(reader.readLine()); } catch (NumberFormatException e) {}
            System.out.print("Enter amplitude (0.0-1.0, default: 0.8): ");
            float amp = 0.8f;
            try { amp = Float.parseFloat(reader.readLine()); } catch (NumberFormatException e) {}
            if (amp < 0 || amp > 1) amp = 0.8f;
            System.out.print("Enter duration (seconds, default: 2.0): ");
            float dur = 2.0f;
            try { dur = Float.parseFloat(reader.readLine()); } catch (NumberFormatException e) {}
            if (dur <= 0) dur = 2.0f;
            System.out.print("Enter sample rate (Hz, default: 44100): ");
            int rate = 44100;
            try { rate = Integer.parseInt(reader.readLine()); } catch (NumberFormatException e) {}
            System.out.print("Enter output filename (default: output.wav): ");
            String fname = reader.readLine().trim();
            if (fname.isEmpty()) fname = "output.wav";
            if (!fname.endsWith(".wav")) fname += ".wav";
            Wave gen = new Wave(freq, amp, dur, rate, wtype);
            gen.saveWAV(fname);
            System.out.println("Saved to " + fname);
            System.out.print("Play? (y/n, default: y): ");
            String play = reader.readLine().trim().toLowerCase();
            if (!play.equals("n")) gen.play(fname);
        }
    }
}
