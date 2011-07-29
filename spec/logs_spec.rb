require 'spec_helper'

module Kannel
  module Log
    describe "Log.parse(log_file)" do
      it "should not raise any errors. Is a shorthand for Parser.new(log_file).parse" do
        lambda { Kannel::Log.parse('spec/support/kannel-current.log') }.should_not raise_error
      end
    end

    describe Parser do
      let(:log_file) { 'spec/support/kannel-current.log' }
      let(:parser)   { Parser.new(log_file) }

      describe "#new" do
        it "should raise ArgumentError if the log file isn't readable" do
          lambda { Parser.new('spec/support/i-dont-exist.4923') }.should raise_error(ArgumentError)
        end
      end

      describe "#parse" do
        it "should return an array of all rows with a status of WARNING,ERROR,PANIC" do
          parser.parse().size == 3
        end

        it "should only be rows in the 'error_types' attribute" do
          parser.parse.reject {|x| parser.error_types.include? x.type }.size.should == 0
        end
      end

      describe "#parse_row" do
        let(:log_row) { '2010-09-17 23:12:56 [21180] [7] ERROR: AT2[modem1]: CMS ERROR: +CMS ERROR: 500' }
        let(:row) { parser.parse_row(log_row) }

        it "should return an instance of Kannel::Log::Row" do
          row.is_a?(Kannel::Log::Row).should == true
        end

        it "should get back the correct date time, error type and message" do
          row.datetime.should == Time.parse('2010-09-17 23:12:56')
          row.type.should == :ERROR
          row.message.should == 'AT2[modem1]: CMS ERROR: +CMS ERROR: 500'
        end
      end
    end # /Parser

    describe Row do
      let(:row) { Row.new('2010-09-17 23:12:56', 'ERROR', 'AT2[modem1]: CMS ERROR: +CMS ERROR: 500') }
      describe "#new" do
        it "should take three arguments that are strings: datetime, type and message" do
          lambda { Row.new('2010-09-17 23:12:56', 'ERROR', 'AT2[modem1]: CMS ERROR: +CMS ERROR: 500') }.should_not raise_error
        end
      end

      describe "#[]" do
        it "should act as the capture groups of the Regex that gets the data, start from index 1" do
          row[1].should == Time.parse('2010-09-17 23:12:56')
          row[2].should == :ERROR
          row[3].should == 'AT2[modem1]: CMS ERROR: +CMS ERROR: 500'
        end
      end

      describe "#smsc" do
        it "should return the SMS Center if the message string contains one" do
          row.smsc.should == 'modem1'
        end

        it "should return nil if there is no AT2 SMSC in the message string" do
          row = Row.new('2010-09-17 23:12:56', 'ERROR', 'bearerbox: CMS ERROR: +CMS ERROR: 500')
          row.smsc.should == nil
        end
      end
    end # /Row
  end
end
