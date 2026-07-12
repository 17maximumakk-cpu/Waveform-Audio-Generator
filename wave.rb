# wave.rb
require 'optparse'
require 'fileutils'
require 'open3'

class WaveGenerator
  attr_reader :samples

  def initialize(freq: 440, amp: 0.8, duration: 2.0, sample_rate: 44100, wave_type: 'sine')
    @freq = freq
    @amp = amp
    @duration = duration
    @sample_rate = sample_rate
    @wave_type = wave_type
    generate
  end

  def generate
    num_samples = (@sample_rate * @duration).to_i
    @samples = []
    num_samples.times do |i|
      t = i / @sample_rate.to_f
      phase = 2 * Math::PI * @freq * t
      val = case @wave_type
            when 'sine' then Math.sin(phase)
            when 'square' then Math.sin(phase) >= 0 ? 1 : -1
            when 'sawtooth' then 2 * (phase / (2 * Math::PI) - (phase / (2 * Math::PI) + 0.5).floor)
            when 'triangle' then 2 * (2 * (phase / (2 * Math::PI) - (phase / (2 * Math::PI) + 0.5).floor).abs) - 1
            when 'noise' then rand(-1.0..1.0)
            else 0
            end
      @samples << (@amp * val * 32767).round
    end
  end

  def save_wav(filename)
    File.open(filename, 'wb') do |f|
      data_size = @samples.length * 2
      byte_rate = @sample_rate * 2
      # RIFF
      f.write('RIFF')
      f.write([36 + data_size].pack('V'))
      f.write('WAVE')
      # fmt
      f.write('fmt ')
      f.write([16, 1, 1, @sample_rate, byte_rate, 2, 16].pack('VvvVVvv'))
      # data
      f.write('data')
      f.write([data_size].pack('V'))
      @samples.each do |s|
        f.write([s].pack('v'))
      end
    end
  end

  def play(filename)
    os = RUBY_PLATFORM
    cmd = nil
    if os =~ /mswin|mingw|windows/
      cmd = "start #{filename}"
    elsif os =~ /darwin/
      cmd = "afplay #{filename}"
    else
      players = ['ffplay', 'aplay', 'mpg123']
      found = players.find { |p| system("which #{p} > /dev/null 2>&1") }
      cmd = "#{found} #{filename}" if found
    end
    system(cmd) if cmd
  end
end

def interactive
  puts '=== Waveform Audio Generator ==='
  types = ['sine', 'square', 'sawtooth', 'triangle', 'noise']
  print "Enter type (#{types.join(', ')}, default: sine): "
  wtype = gets.chomp.strip
  wtype = 'sine' if wtype.empty? || !types.include?(wtype)
  print 'Enter frequency (Hz, default: 440): '
  freq = gets.to_f
  freq = 440 if freq <= 0
  print 'Enter amplitude (0.0-1.0, default: 0.8): '
  amp = gets.to_f
  amp = 0.8 if amp < 0 || amp > 1
  print 'Enter duration (seconds, default: 2.0): '
  dur = gets.to_f
  dur = 2.0 if dur <= 0
  print 'Enter sample rate (Hz, default: 44100): '
  rate = gets.to_i
  rate = 44100 if rate <= 0
  print 'Enter output filename (default: output.wav): '
  fname = gets.chomp.strip
  fname = 'output.wav' if fname.empty?
  fname += '.wav' unless fname.end_with?('.wav')
  gen = WaveGenerator.new(freq: freq, amp: amp, duration: dur, sample_rate: rate, wave_type: wtype)
  gen.save_wav(fname)
  puts "Saved to #{fname}"
  print 'Play? (y/n, default: y): '
  play = gets.chomp.strip.downcase
  gen.play(fname) unless play == 'n'
end

def cli
  options = {}
  OptionParser.new do |opts|
    opts.on('-f FREQ', '--freq FREQ', Float, 'Frequency in Hz') { |v| options[:freq] = v }
    opts.on('-t TYPE', '--type TYPE', 'Waveform type') { |v| options[:type] = v }
    opts.on('-a AMP', '--amp AMP', Float, 'Amplitude') { |v| options[:amp] = v }
    opts.on('-d DUR', '--dur DUR', Float, 'Duration in seconds') { |v| options[:dur] = v }
    opts.on('-r RATE', '--rate RATE', Integer, 'Sample rate') { |v| options[:rate] = v }
    opts.on('-o OUTPUT', '--output OUTPUT', 'Output filename') { |v| options[:output] = v }
    opts.on('--no-play', 'Disable playback') { options[:no_play] = true }
  end.parse!
  freq = options[:freq] || 440
  wtype = options[:type] || 'sine'
  amp = options[:amp] || 0.8
  dur = options[:dur] || 2.0
  rate = options[:rate] || 44100
  output = options[:output] || 'output.wav'
  no_play = options[:no_play] || false
  gen = WaveGenerator.new(freq: freq, amp: amp, duration: dur, sample_rate: rate, wave_type: wtype)
  gen.save_wav(output)
  puts "Saved to #{output}"
  gen.play(output) unless no_play
end

if ARGV.empty?
  interactive
else
  cli
end
