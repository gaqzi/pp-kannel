#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
$VERBOSE = true
$KCODE = 'u'

module Kannel
  module Log
    def self.parse(log_file)
      Parser.new(log_file).parse
    end

    class Parser
      attr_accessor :error_types

      def initialize(log_file)
        unless File.readable?(log_file)
          raise ArgumentError, "File '#{log_file}' is not readable!"
        end

        @log_file = log_file
        # A kannel log row contains:
        # date time [pid] [some number] MESSAGE_TYPE: event
        # The regexp capture groups are:
        #   1 => datetime
        #   2 => log type
        #   3 => log message
        @regex = Regexp.new('([\d-]+\s[\d:]+)\s' + # Captures datetime
                            '\[\d+\]\s\[\d+\]\s' + # Swallow up uninteresting things
                            '(\w+):\s(.+)$')       # Capture log type and message
        # These are the error types to report
        @error_types = [:WARNING, :ERROR, :PANIC]
      end

      def parse
        interesting_rows = []
        File.open(@log_file) do |file|
          file.each do |row|
            row = parse_row(row)
            if error_types.include? row.type
              interesting_rows << row
            end
          end
        end

        interesting_rows
      end

      def parse_row(row)
        Row.new(*row.match(@regex)[1..3])
      end
    end # /Parser

    class Row
      attr_reader :datetime
      attr_reader :type
      attr_reader :message

      def initialize(datetime, type, message)
        @datetime = Time.parse(datetime)
        @type = type.strip.to_sym
        @message = message.strip
      end

      def [](i)
        case i
        when 1: datetime
        when 2: type
        when 3: message
        else
          nil
        end
      end

      def smsc
        message.match(/^AT2\[(\w+)\]/)[1] rescue nil
      end
    end # /Row
  end # /Log
end # /Kannel
