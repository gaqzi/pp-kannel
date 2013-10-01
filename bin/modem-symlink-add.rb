#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
$VERBOSE = true
$KCODE = 'u'

# Create a symlink to the second device under /dev/modems

def dev_num(dev, regex = 'modem(\d+)')
  dev.match(regex)[1].to_i
end

if ENV['ID_USB_INTERFACE_NUM'] == '02'
  next_num = if File.exists? '/dev/modems/'
               devices = Dir.glob('/dev/modems/modem*')
               if devices.size > 0
                 dev_num(devices.max {|a, b| dev_num(a) <=> dev_num(b) }) + 1
               else
                 0
               end
             else
               Dir.mkdir '/dev/modems'
               0
             end

  device_name = "modem#{next_num}"
  File.symlink(File.join('/dev', ARGV[0]), File.join('/dev/modems', device_name))
  `/usr/local/bin/kannel-manage-smsc.rb start #{device_name}`
end
