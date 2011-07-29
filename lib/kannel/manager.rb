#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
$KCODE = 'u'

require 'open-uri'
require 'kannel/status'

class InvalidSMSC < ArgumentError ; end

module Kannel
  class Manager
    # Valid arguments are:
    # :config         :: The Kannel SMSC configuration file
    # :admin_password :: The password to administer Kannel through the admin site
    # :admin_url      :: The base URL for the Kannel admin site
    def initialize(opts = {})
      @opts = {
        :config         => '/etc/kannel/sms-centers.conf',
        :admin_password => nil,
        :admin_url      => 'http://localhost:13000/',
      }.merge(opts)
      @centers = configuration_parser(@opts[:config])
      @online_smscs = [] # A list of all SMS Centers that are online
    end
    def status_url ; @opts[:status_url] ? @opts[:status_url] : @opts[:admin_url] ; end

    def smsc(smsc)            ; @centers[smsc]           ; end
    def sms_centers           ; @centers.keys            ; end
    def valid_device?(smsc)   ; @centers.index(smsc)     ; end
    def device_accessible?(device) ; File.exist?(device) ; end
    alias_method :valid_smsc?, :smsc

    def start(smsc) ; start_or_stop(smsc, 'start') ; end
    def stop(smsc)  ; start_or_stop(smsc, 'stop')  ; end

    def start_all
      @centers.each {|smsc, device| start(smsc) }
    end

    def stop_all_inaccessible
      @centers.each do |smsc, device|
        stop(smsc) unless device_accessible?(device)
      end
    end

    def stop_all
      @centers.each do |smsc, device|
        stop(smsc)
      end
    end

    def set_log_level(level)
      unless level.to_s.match(/^[0-4]$/)
        raise ArgumentError, "Level has to be an integer between 0 and 4. '#{level}' passed in."
      end

      url = File.join(@opts[:admin_url], "log-level?level=#{level}") + admin_password
      res = open(url).read

      if res.match(/log-level set to/i)
        level.to_i
      else
        raise RuntimeError, "Error when setting new log level: '#{res}'"
      end
    end

    private
    def start_or_stop(smsc, type)
      device = @centers[smsc]
      if device.nil?
        raise InvalidSMSC, "'#{smsc}' is not a configured SMS Center"
      end

      if @online_smscs.empty?
        @online_smscs = Kannel::Status.new(status_url).active_smscs
      end

      # Do not start or stop a SMS Center that is already started/stopped
      if((type == 'stop' and not @online_smscs.include?(smsc)) \
         or (type == 'start' and @online_smscs.include?(smsc)))
        return true
      end

      # If the device is accessible and it is not already the status we want,
      # act on it!
      if device_accessible?(device) or type == 'stop'
        code = open(generate_smsc_url(smsc, type)).read

        if type == 'start' and code.match(/started/)
          @online_smscs << smsc
          true
        elsif type == 'stop' and code.match(/shut down/)
          @online_smscs.delete smsc
          true
        else
          raise RuntimeError, "An unknown error occurred when handling SMSC '#{smsc}': '#{code}'"
        end
      else
        raise RuntimeError, "The SMSC '#{smsc}' could not be started because the TTY-device does not exist!"
      end
    end

    def generate_smsc_url(smsc, type = 'start')
      File.join(@opts[:admin_url], "#{type}-smsc.txt?smsc=#{smsc}") + admin_password
    end

    def admin_password
      if @opts[:admin_password]
        "&password=#{@opts[:admin_password]}"
      else
        ''
      end
    end

    # Assume that the configuration file is only going to contain sms centers.
    # And that the `smsc-id` is always going to be before `device`.
    def configuration_parser(file)
      centers = {}

      unless File.readable?(file)
        raise ArgumentError, "#{file} is not readable. Does it exist?"
      end

      File.open(file) do |f|
        current_smsc = ''
        f.each do |row|
          if smsc = row.match(/^smsc-id ?= ?(.*)/)
            current_smsc = smsc[1].strip
          elsif device = row.match(/device ?= ?(.*)/)
            centers[current_smsc] = device[1].strip unless current_smsc.empty?
            current_smsc = ''
          end
        end
      end

      centers
    end
  end # /Manager
end # /Kannel
