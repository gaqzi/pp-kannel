#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
$KCODE = 'u'

require 'yaml'
require 'kannel/status'

module Kannel
  module State
    def self.bearerbox(admin_path)
      box = Bearerbox.new(admin_path)
      box.load

      box
    end

    def self.cache(cache_file)
      cache = Cache.new(cache_file)
      cache.load

      cache
    end

    class Bearerbox
      attr :status,            :writable
      attr :uptime                       # In seconds
      attr :messages_sent,     :writable
      attr :messages_received, :writable
      attr :messages_queued,   :writable
      attr :messages_stored,   :writable
      attr :last_update,       :writable

      def initialize(admin_path)
        @status = Kannel::Status.new(admin_path)
      end

      def uptime=(uptime)
        @uptime = convert_kannel_uptime_to_seconds(uptime)
      end

      def load
        @status.bearerbox.each {|k, v| self.send("#{k}=", v) }
        last_update = Time.now
      end

      private
      def convert_kannel_uptime_to_seconds(uptime)
        uptime = uptime.split(' ')
        uptime.inject(0) do |memo, part|
          multiplier, period = part.scan(/(\d+)([dhms])/).flatten
          multiplier = multiplier.to_i

          memo += case period
                  when 'd': multiplier * (24 * 3600)
                  when 'h': multiplier * 3600
                  when 'm': multiplier * 60
                  when 's': multiplier
                  end
        end
      end
    end # /Bearerbox

    class Cache
      def initialize(cache_file)
        unless File.readable?(cache_file)
          raise ArgumentError, "The file '#{cache_file}' is not accessible"
        end

        @cache_file  = cache_file
        @cache       = {}
        @local_cache = {}
        @new_cache   = {}
      end

      def load      ; @cache = YAML.load_file(@cache_file) ; end
      def []=(k, v) ; @local_cache[k] = v                  ; end
      def [](k)     ; @local_cache[k] || @cache[k]         ; end

      def smsc(smsc = false)
        if smsc
          self[:smsc][smsc] or 0
        else
          self[:smsc]
        end
      end

      def increment_smsc(smsc)
        # To be able to easily increment copy the old cached increment values
        @local_cache[:smsc] ||= @cache[:smsc] || {}
        @local_cache[:smsc][smsc] = smsc(smsc) + 1
      end

      def save(debug = false)
        @new_cache = @cache.merge(@local_cache)
        @new_cache[:last_updated] = (@local_cache[:last_updated] or Time.now)

        @new_cache.merge!(ìncrement_stored_same?)
        @new_cache.merge!(new_month?(@new_cache[:last_updated], self[:current_month]))
        @new_cache.merge!(restarted?)

        if debug
          @new_cache
        else
          File.open(@cache_file, 'w+') do |file|
            file.write(YAML.dump(@new_cache))
          end
        end
      end

      private
      def ìncrement_stored_same?
        if @cache[:stored_messages] == 0 && @local_cache[:stored_messages].nil?
          {}
        else
          {:stored_same_count => (self[:stored_same_count] or 0) + 1}
        end
      end

      def new_month?(timestamp, current_month)
        if(timestamp.month != current_month)
          {
            :current_month => timestamp.month,
            :messages_sent => 0,
          }
        else
          {}
        end
      end

      def restarted?
        if @local_cache[:uptime] < @cache[:uptime]
          {:smsc => {}}
        else
          {}
        end
      end
    end # /Cache
  end # /State
end # /Kannel
