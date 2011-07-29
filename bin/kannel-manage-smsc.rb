#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
$KCODE = 'u'

require 'rubygems'
require 'yaml'

begin
  require 'kannel/manager'
rescue LoadError
  $:.unshift(File.join(File.expand_path(File.dirname(__FILE__)), '../lib'))
  require 'kannel/manager'
end

config_file = '/etc/kannel-manage-smsc.yml'
if File.exist?(config_file)
  config = YAML.load_file(config_file)
else
  STDERR.puts 'No configuration file found.'
  STDERR.puts 'Copy the file below and configure it to your needs.'
  STDERR.puts "cp #{File.join(File.dirname(__FILE__), '../etc/kannel-manage-smsc.yml')} /etc/"
  exit 1
end

def usage
  STDERR.puts "Usage: #{File.basename(__FILE__)} start | stop | log-level <argument>"
  STDERR.puts "\tstart | stop <SMSC>"
  STDERR.puts "\tSMSC is equal to a SMS Center configured in the Kannel config"
  STDERR.puts "\tOr you can use:"
  STDERR.puts "\tALL will start or stop all SMS Centers"
  STDERR.puts "\tALL_INACCESSIBLE will stop all SMS Centers"
  STDERR.puts "\t                 that don't have a modem available"
  STDERR.puts
  STDERR.puts "\tlog-level <0-4> Sets Kannels log level to this value. Lower is more"
end

if ARGV.size != 2
  usage()
  exit 0
end

kannel = Kannel::Manager.new(config)
case (ARGV[0] or '').downcase
when 'start'
  if ARGV[1].downcase == 'all'
    kannel.start_all
  else
    if kannel.start(ARGV[1])
      puts "#{ARGV[1]} started"
    else
      puts "#{ARGV[1]} could not be started"
    end
  end

when 'stop'
  case ARGV[1].downcase
  when 'all'
    kannel.stop_all
  when 'all_inaccessible'
    kannel.stop_all_inaccessible
  else
    if kannel.stop(ARGV[1])
      puts "#{ARGV[1]} stopped"
    else
      puts "#{ARGC[1]} could not be stopped"
    end
  end

  # Will raise exceptions if any problems occur
when 'log-level'
  begin
    kannel.set_log_level(ARGV[1])
    puts "Log level set to '#{ARGV[1]}'"
  rescue ArgumentError => e
    STDERR.puts e.message
  rescue RuntimeError => e
    STDERR.puts e.message
  end
else
  usage()
end

