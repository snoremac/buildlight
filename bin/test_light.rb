#!/usr/bin/env ruby

require 'rubygems'
require 'usb'

index = ARGV[0]
colours = ["\x01", "\x02", "\x04", "\x03", "\x05", "\x06", "\x07", "\x00"]
colour = colours[ARGV[1].to_i]

devices = USB.devices.find_all{|device| device.idVendor == 0x0fc5 && device.idProduct == 0xb080}
device = devices[index.to_i]
puts "device num: #{device.devnum} from a list of #{devices.map {|d| d.devnum }.join(',')}"

puts "Opening device..."
handle = device.open
begin	
handle.usb_detach_kernel_driver_np(0, 0)
rescue
puts "Unable to detach"
end
handle.set_configuration(device.configurations.first)
handle.claim_interface(0)
puts "Setting colour..."
handle.usb_control_msg(0x21, 0x09, 0x0635, 0x000, "\x65\x0C#{colour}\xFF\x00\x00\x00\x00", 0)
puts "Releasing..."
handle.release_interface(0)
handle.usb_close



