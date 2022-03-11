#!/usr/bin/env ruby

require 'libusb'
require 'date'

class EverdriveIO
  class DeviceNotFound < StandardError; end

  def initialize(vendor, product)
    @device = find_device(vendor, product)
    @input, @output = find_bulk_endpoints(device)
    @handle = device.open
    handle.claim_interface(input.interface)
  end

  def inspect
    "#<#{self.class.name}: #{device.inspect}>"
  end

  def close
    handle.close
  end

  def read(length)
    handle.bulk_transfer(endpoint: input, dataIn: length)
  end

  def write(data)
    handle.bulk_transfer(endpoint: output, dataOut: data)
  end

  def read_u8
    read(1).ord
  end

  def read_u16
    read(2).unpack('S').first
  end

  def read_u32
    read(4).unpack('L').first
  end

  def write_u8(u8)
    write(
      (u8 & 0xff).chr
    )
  end

  def write_u16(u16)
    write(
      [
        (u16 & 0x00ff),
        (u16 & 0xff00) >> 8
      ].pack('cc')
    )
  end

  def write_u32(u32)
    write(
      [
        (u32 & 0x000000ff),
        (u32 & 0x0000ff00) >> 8,
        (u32 & 0x00ff0000) >> 32,
        (u32 & 0xff000000) >> 24,
      ].pack('cccc')
    )
  end

  def write_string(string)
    write_u16(string.length)
    write(string)
  end

  private

  attr_reader :input, :output, :handle, :device

  def find_device(vendor, product)
    LIBUSB::Context.new.devices(idVendor: vendor, idProduct: product).first.tap do |device|
      raise(DeviceNotFound) if device.nil?
    end
  end

  def find_bulk_endpoints(device)
    [
      device.endpoints.find { |ep| ep.transfer_type == :bulk && ep.direction == :in },
      device.endpoints.find { |ep| ep.transfer_type == :bulk && ep.direction == :out }
    ]
  end
end


class Everdrive
  VENDOR = 0x0483
  PRODUCT = 0x5740
  STATUS_OK = 0xa500

  FAT_WRITE = 0x02
  FAT_OPEN_ALWAYS = 0x10

  CMD_F_FCLOSE = 0xCE;
  CMD_F_FOPN = 0xC9
  CMD_F_FWR = 0xCC
  CMD_RTC_GET = 0x14;
  CMD_STATUS = 0x10


  def initialize
    @everdrive = EverdriveIO.new(VENDOR, PRODUCT)
    p status_ok?
  end

  def inspect
    "#<#{self.class.name}: #{@everdrive.inspect}>"
  end

  def status_ok?
    everdrive.write(make_command(CMD_STATUS))
    everdrive.read_u16 == STATUS_OK
  end

  def get_realtime_clock
    everdrive.write(make_command(CMD_RTC_GET))
    rtc = everdrive.read(6)

    ary = rtc.split('').map{|c| ('%x' % c.ord).to_i }
    DateTime.new(ary[0] + 2000, ary[1], ary[2], ary[3], ary[4], ary[5])
  end

  def test_write_file
    filename = '000-test.nes'
    File.open(filename, 'rb') do |fp|
      contents = fp.read
      p file_open(filename, FAT_OPEN_ALWAYS | FAT_WRITE)
      p file_write(contents, 0, contents.length)
      p file_close
    end
  end

  private

  attr_reader :everdrive

  def file_open(filename, mode)
    puts 'file_open'
    everdrive.write(make_command(CMD_F_FOPN))
    everdrive.write_u8(mode)
    everdrive.write_string('000-test.nes')
    status_ok?
  end

  def file_write(data, notsure, length)
    puts 'file_write'
    everdrive.write(make_command(CMD_F_FWR))
    everdrive.write_u32(data.length)
    everdrive.write(data)
    # other stuff txdataack instead, pay attention to blocksizes
    status_ok?
  end

  def file_close
    puts 'file_close'
    everdrive.write(make_command(CMD_F_FCLOSE))
    status_ok?
  end

  def make_command(command_code)
    data = ['+', '+'.ord ^ 0xff, command_code, command_code ^ 0xff].map { |b| (b.ord & 0xff).chr }.join
  end
end

everdrive = Everdrive.new
p everdrive.get_realtime_clock
# p everdrive.test_write_file
