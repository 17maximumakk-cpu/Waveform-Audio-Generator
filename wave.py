# wave.py
import argparse
import math
import struct
import wave
import os
import subprocess
import platform
from typing import Optional

class WaveGenerator:
    def __init__(self, freq=440, amp=0.8, duration=2.0, sample_rate=44100, wave_type='sine'):
        self.freq = freq
        self.amp = amp
        self.duration = duration
        self.sample_rate = sample_rate
        self.wave_type = wave_type
        self.samples = []
        self._generate()

    def _generate(self):
        num_samples = int(self.sample_rate * self.duration)
        for i in range(num_samples):
            t = i / self.sample_rate
            phase = 2 * math.pi * self.freq * t
            if self.wave_type == 'sine':
                val = math.sin(phase)
            elif self.wave_type == 'square':
                val = 1 if math.sin(phase) >= 0 else -1
            elif self.wave_type == 'sawtooth':
                val = 2 * (phase / (2 * math.pi) - math.floor(phase / (2 * math.pi) + 0.5))
            elif self.wave_type == 'triangle':
                val = 2 * abs(2 * (phase / (2 * math.pi) - math.floor(phase / (2 * math.pi) + 0.5))) - 1
            elif self.wave_type == 'noise':
                import random
                val = random.uniform(-1, 1)
            else:
                val = 0
            self.samples.append(int(self.amp * val * 32767))

    def save_wav(self, filename: str):
        with wave.open(filename, 'w') as wf:
            wf.setnchannels(1)
            wf.setsampwidth(2)  # 16-bit
            wf.setframerate(self.sample_rate)
            data = struct.pack('<' + 'h' * len(self.samples), *self.samples)
            wf.writeframes(data)

    def play(self, filename: str):
        system = platform.system()
        try:
            if system == 'Windows':
                os.startfile(filename)
            elif system == 'Darwin':
                subprocess.run(['afplay', filename], check=True)
            else:
                players = ['ffplay', 'aplay', 'mpg123']
                for player in players:
                    try:
                        subprocess.run([player, filename], check=True)
                        return
                    except FileNotFoundError:
                        continue
                print('No suitable player found.')
        except Exception as e:
            print(f'Playback error: {e}')

def interactive():
    print('=== Waveform Audio Generator ===')
    types = ['sine', 'square', 'sawtooth', 'triangle', 'noise']
    wtype = input(f'Enter type ({", ".join(types)}, default: sine): ').strip() or 'sine'
    if wtype not in types:
        wtype = 'sine'
    freq = float(input('Enter frequency (Hz, default: 440): ').strip() or '440')
    amp = float(input('Enter amplitude (0.0-1.0, default: 0.8): ').strip() or '0.8')
    dur = float(input('Enter duration (seconds, default: 2.0): ').strip() or '2.0')
    rate = int(input('Enter sample rate (Hz, default: 44100): ').strip() or '44100')
    fname = input('Enter output filename (default: output.wav): ').strip() or 'output.wav'
    if not fname.endswith('.wav'):
        fname += '.wav'
    gen = WaveGenerator(freq, amp, dur, rate, wtype)
    gen.save_wav(fname)
    print(f'Saved to {fname}')
    if input('Play? (y/n, default: y): ').strip().lower() != 'n':
        gen.play(fname)

def cli():
    parser = argparse.ArgumentParser(description='Waveform Audio Generator')
    parser.add_argument('-f', '--freq', type=float, default=440, help='Frequency in Hz')
    parser.add_argument('-t', '--type', default='sine', choices=['sine','square','sawtooth','triangle','noise'], help='Waveform type')
    parser.add_argument('-a', '--amp', type=float, default=0.8, help='Amplitude (0.0-1.0)')
    parser.add_argument('-d', '--dur', type=float, default=2.0, help='Duration in seconds')
    parser.add_argument('-r', '--rate', type=int, default=44100, help='Sample rate')
    parser.add_argument('-o', '--output', default='output.wav', help='Output filename')
    parser.add_argument('--no-play', action='store_true', help='Don\'t play after generation')
    args = parser.parse_args()
    gen = WaveGenerator(args.freq, args.amp, args.dur, args.rate, args.type)
    gen.save_wav(args.output)
    print(f'Saved to {args.output}')
    if not args.no_play:
        gen.play(args.output)

if __name__ == '__main__':
    import sys
    if len(sys.argv) > 1:
        cli()
    else:
        interactive()
