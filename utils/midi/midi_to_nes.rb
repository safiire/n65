#!/usr/bin/env ruby

require 'yaml'

class MidiToNES

  ####  Custom Exceptions
  class MidiFormatNotSupported < StandardError; end

  ####  Some Constants
  NoteOff = 0x8
  NoteOn  = 0x9

  ####  A440 Tuning, and NES CPU speed in hz
  Tuning = 440.0
  CPU    = 1789773.0


  ####  LSB Address registers of the APU, MSB is always 0x40
  Pulse1Control = 0x00
  Pulse1FT = 0x2
  Pulse1CT = 0x3


  ####
  ##  Initialize from a yaml file
  def self.init_from_file(filename, bpm)
    self.new(File.read(filename), bpm)
  end


  ####
  ##  Initialize with a yaml string
  def initialize(yaml_string, bpm)
    @bpm = bpm.to_f
    @midi_data = YAML.load(yaml_string)[:midi_file]
    unless @midi_data[:format].zero?
      fail(MidiFormatNotSupported, "Currently only supports format 0 Midi Files")
    end
    @ticks_per_quarter_note = @midi_data[:ticks_per_quarter_note]
  end


  ####
  ##  Write to binary file
  def write_binary(filename)
    binary = convert
    File.open(filename, 'wb') do |fp|
      fp.write(binary)
    end
  end


  ####
  ##  For now assume one track
  def convert
    tick_count = 1
    events = []

    track = @midi_data[:tracks].first
    track[:events].each do |event|

      delta, status, note, velocity = event.values_at(:delta, :status, :parameter1, :parameter2)

      ##  The status byte contains both the Midi message type, and channel.
      type =   (status & 0b11110000) >> 4
      channel = status & 0b00001111

      ##  We only care about note on and off, and only care about channel 0 for now.
      next unless type == NoteOn || type == NoteOff
      next unless channel.zero?

      ##  Update the total time
      tick_count += delta

      ##  Ok this is a note either turning on or off
      if type == NoteOff || velocity.zero?
        event = {:start => tick_count, :note => note, :velocity => 0}
        events << event
      else
        event = {:start => tick_count, :note => note, :velocity => velocity}
        events << event
      end
    end

    ##  Finally sort event list by start time
    events.sort! do |a, b|
      a[:start] <=> b[:start]
    end

    ##  Now convert these events to a bytestream for our NES sound engine
    events_to_byte_stream(events)
  end


  ####
  ##  This converts a list of note events into a byte stream for updating NES APU registers
  def events_to_byte_stream(events)
    last_tick = 1
    byte_stream = []

    events.each do |event|
      ##  Work out the delta again
      delta = event[:start] - last_tick
      byte_stream << midi_tick_to_vblank(delta)   #  Delta
      byte_stream << pulse_control_value(event)   #  Value
      if event[:velocity].zero?
        byte_stream << 0                          #  Off with 0 frequency timer
        byte_stream << 0
      else
        byte_stream << pulse_ft_value(event)      #  Value
        byte_stream << pulse_ct_value(event)      #  Value
      end
      last_tick += delta
    end
    byte_stream.pack('C*')
  end


  ####
  ##  Given an event, produce a value for register nes.apu.pulse1.control
  ##  DDLC VVVV 
  ##  Duty (D), envelope loop / length counter halt (L), constant volume (C), volume/envelope (V)
  def pulse_control_value(event)
    ##  Start with 50% duty cycle, length counter halt is on
    ##  Constant volume is On, and volume is determined by bit-reducing the event velocity to 4-bit
    value = 0b10110000         

    four_bit_max  = (2**4 - 1)
    seven_bit_max = (2**7 - 1)

    volume_float = event[:velocity] / seven_bit_max.to_f
    volume_4_bit = (volume_float * four_bit_max).round & 0b00001111

    value | volume_4_bit
  end


  ####
  ##  Given an event, produce a value for register nes.apu.pulse1.ft
  ##  TTTT TTTT
  ##  This is the low byte of the timer, the higher few bits being in pulse1.ct
  def pulse_ft_value(event)
    midi_note_to_nes_timer(event[:note]) & 0xff
  end


  ####
  ##  Given an event, produce a value for register nes.apu.pulse1.ct
  ##  LLLL LTTT
  ##  This has the higher 3 bits of the timer, and L is the length counter.
  ##  For now let's just use duration as the length counter.
  def pulse_ct_value(event)

    ##  We will grab the high 3 bits of the 11-bit timer value now
    timer_high_3bit = midi_note_to_nes_timer(event[:note]) & 0b11100000000
    timer_high_3bit >> 8
  end


  ####
  ##  Midi note to NES timer
  def midi_note_to_nes_timer(midi_note)
    frequency = Tuning * 2**((midi_note - 69) / 12.0)
    timer = (CPU / (16 * frequency)) - 1
    timer.round
  end


  ####
  ##  Convert a MIDI tick delta to an NES vblank delta.
  def midi_tick_to_vblank(midi_tick)
    quarter_note_in_seconds = 60 / @bpm
    vblanks_per_quarter_note = quarter_note_in_seconds / (1/60.0)
    tick_normalized = midi_tick / @ticks_per_quarter_note.to_f
    vblanks = tick_normalized * vblanks_per_quarter_note
    vblanks.round
  end

end

if __FILE__ == $0
  unless ARGV.size == 2
    STDERR.puts("Usage #{$0} <bpm> <music.mid>")
    exit(1)
  end

  bpm, midi_file = ARGV

  ##  Run the midi file through my converter written in C++
  IO.popen("./convert #{midi_file}") do |io|
    midi_to_nes = MidiToNES.new(io.read, bpm.to_i)
    midi_to_nes.write_binary('../../data.mus')
  end

end




