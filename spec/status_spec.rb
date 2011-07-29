require 'spec_helper'

module Kannel
  describe Status do
    let(:status) { Status.new('spec/support/') }

    describe "#new" do
      it "should take an argument that is the base path to query the Kannel admin" do
        Status.new('spec/support')
      end
    end

    describe "#active_smsc should give back a list of currently active SMS Centers" do
      it "should contain 1 active SMS Center" do
        status.active_smscs.size.should == 1
      end

      it "should have 'modem0' listed as active" do
        status.active_smscs.include?('modem0').should == true
      end
    end

    describe "#smsc_active?" do
      it "should return true if the SMS Center is active" do
        status.smsc_active?('modem0').should == true
      end

      it "should return false if the SMS Center is inactive" do
        status.smsc_active?('modem1').should == false
      end

      it "should raise RuntimeError when the SMS Center is not found or status not active or inactive" do
        lambda { status.smsc_active?('modem-1') }.should raise_error(RuntimeError)
      end
    end

    describe "#bearerbox" do
      it "should return a hash with the current status of Kannels bearerbox" do
        status.bearerbox.is_a?(Hash).should == true
      end

      it "should give the values in the status.xml" do
        data = status.bearerbox
        data[:status].should            == :running
        data[:uptime].should            == '0d 8h 12m 5s'
        data[:messages_sent].should     == 416
        data[:messages_queued].should   == 0
        data[:messages_stored].should   == 0
        data[:messages_received].should == 8
      end
    end
  end # /Status
end # /Kannel
