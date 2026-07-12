// wave.js
const fs = require('fs');
const readline = require('readline');
const { exec } = require('child_process');

const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout
});

class WaveGenerator {
    constructor(freq = 440, amp = 0.8, duration = 2.0, sampleRate = 44100, waveType = 'sine') {
        this.freq = freq;
        this.amp = amp;
        this.duration = duration;
        this.sampleRate = sampleRate;
        this.waveType = waveType;
        this.samples = [];
        this.generate();
    }

    generate() {
        const numSamples = Math.floor(this.sampleRate * this.duration);
        for (let i = 0; i < numSamples; i++) {
            const t = i / this.sampleRate;
            const phase = 2 * Math.PI * this.freq * t;
            let val = 0;
            switch (this.waveType) {
                case 'sine':
                    val = Math.sin(phase);
                    break;
                case 'square':
                    val = Math.sin(phase) >= 0 ? 1 : -1;
                    break;
                case 'sawtooth':
                    val = 2 * (phase / (2 * Math.PI) - Math.floor(phase / (2 * Math.PI) + 0.5));
                    break;
                case 'triangle':
                    val = 2 * Math.abs(2 * (phase / (2 * Math.PI) - Math.floor(phase / (2 * Math.PI) + 0.5))) - 1;
                    break;
                case 'noise':
                    val = Math.random() * 2 - 1;
                    break;
                default:
                    val = 0;
            }
            this.samples.push(Math.round(this.amp * val * 32767));
        }
    }

    saveWAV(filename) {
        const dataSize = this.samples.length * 2;
        const byteRate = this.sampleRate * 2;
        const buffer = Buffer.alloc(44 + dataSize);
        let offset = 0;
        const writeU32 = (v) => { buffer.writeUInt32LE(v, offset); offset += 4; };
        const writeU16 = (v) => { buffer.writeUInt16LE(v, offset); offset += 2; };
        // RIFF
        buffer.write('RIFF', 0);
        writeU32(36 + dataSize);
        buffer.write('WAVE', 8);
        // fmt
        buffer.write('fmt ', 12);
        writeU32(16);
        writeU16(1);
        writeU16(1);
        writeU32(this.sampleRate);
        writeU32(byteRate);
        writeU16(2);
        writeU16(16);
        // data
        buffer.write('data', offset);
        offset += 4;
        writeU32(dataSize);
        // samples
        for (const s of this.samples) {
            buffer.writeInt16LE(s, offset);
            offset += 2;
        }
        fs.writeFileSync(filename, buffer);
    }

    play(filename) {
        const platform = process.platform;
        let cmd;
        if (platform === 'win32') {
            cmd = `start "" "${filename}"`;
        } else if (platform === 'darwin') {
            cmd = `afplay "${filename}"`;
        } else {
            // Linux
            const players = ['ffplay', 'aplay', 'mpg123'];
            // We'll try using the first available
            cmd = `ffplay "${filename}" || aplay "${filename}" || mpg123 "${filename}"`;
        }
        exec(cmd, (err) => {
            if (err) console.log('Playback error:', err.message);
        });
    }
}

function ask(question) {
    return new Promise(resolve => rl.question(question, resolve));
}

async function interactive() {
    console.log('=== Waveform Audio Generator ===');
    const types = ['sine', 'square', 'sawtooth', 'triangle', 'noise'];
    let wtype = await ask(`Enter type (${types.join(', ')}, default: sine): `);
    wtype = wtype.trim() || 'sine';
    if (!types.includes(wtype)) wtype = 'sine';
    let freq = parseFloat(await ask('Enter frequency (Hz, default: 440): ') || '440');
    if (isNaN(freq) || freq <= 0) freq = 440;
    let amp = parseFloat(await ask('Enter amplitude (0.0-1.0, default: 0.8): ') || '0.8');
    if (isNaN(amp) || amp < 0 || amp > 1) amp = 0.8;
    let dur = parseFloat(await ask('Enter duration (seconds, default: 2.0): ') || '2.0');
    if (isNaN(dur) || dur <= 0) dur = 2.0;
    let rate = parseInt(await ask('Enter sample rate (Hz, default: 44100): ') || '44100');
    if (isNaN(rate) || rate <= 0) rate = 44100;
    let fname = await ask('Enter output filename (default: output.wav): ');
    fname = fname.trim() || 'output.wav';
    if (!fname.endsWith('.wav')) fname += '.wav';
    const gen = new WaveGenerator(freq, amp, dur, rate, wtype);
    gen.saveWAV(fname);
    console.log(`Saved to ${fname}`);
    const playAns = await ask('Play? (y/n, default: y): ');
    if (playAns.trim().toLowerCase() !== 'n') {
        gen.play(fname);
    }
    rl.close();
}

function cli() {
    const args = require('minimist')(process.argv.slice(2));
    const freq = args.f || args.freq || 440;
    const wtype = args.t || args.type || 'sine';
    const amp = args.a || args.amp || 0.8;
    const dur = args.d || args.dur || 2.0;
    const rate = args.r || args.rate || 44100;
    const output = args.o || args.output || 'output.wav';
    const noPlay = args['no-play'] || false;
    const gen = new WaveGenerator(parseFloat(freq), parseFloat(amp), parseFloat(dur), parseInt(rate), wtype);
    gen.saveWAV(output);
    console.log(`Saved to ${output}`);
    if (!noPlay) gen.play(output);
}

if (process.argv.length > 2) {
    cli();
} else {
    interactive();
}
