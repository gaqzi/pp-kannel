#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
$KCODE = 'u'

require 'nokogiri'

module Kannel
  class Status
    def initialize(url)
      @base_url = url
      @doc = {}
    end

    def active_smscs(path = 'status.xml')
      doc = xml_search(path)
      doc.xpath('//smsc[status!="dead"]/id').map {|el| el.inner_text }
    end
    alias :active_smsc :active_smscs

    def smsc_active?(smsc, path = 'status.xml')
      doc = xml_search(path)
      status = doc.xpath("//smsc[id='#{smsc.strip}']/status").inner_text

      if status.match(/online/)
        true
      elsif status.match(/dead/)
        false
      else
        raise RuntimeError, "An unknown error occurred when checking status for SMSC '#{smsc}': '#{status}'"
      end
    end

    def bearerbox(path = 'status.xml')
      doc = xml_search(path)
      data = {}

      status = doc.at_xpath('/gateway/status').inner_text.split(',')
      data[:status] = status[0].strip.to_sym
      data[:uptime] = status[1].sub('uptime', '').strip

      sms = doc.at_xpath('/gateway/sms')
      data.merge({
        :messages_sent     => sms.at_xpath('sent/total'    ).content.to_i,
        :messages_queued   => sms.at_xpath('sent/queued'   ).content.to_i,
        :messages_stored   => sms.at_xpath('storesize'     ).content.to_i,
        :messages_received => sms.at_xpath('received/total').content.to_i
      })
    end

    private
    def xml_search(path)
      @doc[path] ||= Nokogiri::XML(open((File.join(@base_url, path))))
    end
  end # /Status
end # /Kannel
