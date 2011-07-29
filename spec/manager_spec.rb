require 'spec_helper'

module Kannel
  describe Manager do
    let(:kannel) { Manager.new(:config => 'spec/support/sms-centers.conf',
                               :admin_url => 'http://localhost:65000',
                               :status_url => 'spec/support') }

    describe "#new" do
      it "should raise ArgumentError when the configuration isn't readable" do
        lambda { Manager.new(:config => 'sms-centers.conf') }.should raise_error(ArgumentError)
      end

      it 'should then know that there are two valid SMS Centers' do
        kannel.sms_centers.size == 2
      end
    end

    describe "#valid_smsc?" do
      it "should return the tty-device of a valid SMS Center" do
        kannel.valid_smsc?('modem0').should == 'spec/support/tty/modem0'
      end

      it "should return nil for an invalid SMS Center" do
        kannel.valid_smsc?('modem-1').should == nil
      end
    end

    describe "#valid_device?" do
      it 'should return the SMS Center id for a valid TTY device' do
        kannel.valid_device?('spec/support/tty/modem0').should == 'modem0'
      end

      it 'should return nil for an invalid TTY device' do
        kannel.valid_device?('/dev/modems/modem-1').should == nil
      end
    end

    describe '#device_accessible?' do
      it 'should return true if the device exists on the file system' do
        kannel.device_accessible?(kannel.valid_smsc?('modem0')).should == true
      end

      it "should return false if the device doesn't exist on the file system" do
        kannel.device_accessible?(kannel.valid_smsc?('modem1')).should == false
      end
    end

    describe "#start" do
      before { kannel.stub(:open) }
      it "should return true when trying to start a valid SMSC that is not already started and TTY-device exists" do
        read = mock('open')
        read.stub(:read).and_return("SMSC `modem2' started")
        kannel.should_receive(:open).and_return(read)

        kannel.start('modem2').should == true
      end

      it "should raise 'RuntimeError' when trying to start a valid SMSC but the TTY-device does not exist" do
        lambda { kannel.start('modem1') }.should raise_error(RuntimeError)
      end

      it "'InvalidSMSC' should be raised when trying to start an invalid SMSC" do
        lambda { kannel.start('modem-1') }.should raise_error(InvalidSMSC)
      end

      it "should return true when trying to start a valid SMSC that is already started" do
        kannel.start('modem0').should == true
      end
    end

    describe "#set_log_level" do
      let(:read) { mock('open') }
      before     { kannel.stub(:open) }


      it "should return the new log-level when the log level was set successfully" do
        read.stub(:read).and_return('log-level set to 1')
        kannel.should_receive(:open).and_return(read)

        kannel.set_log_level(1).should == 1
      end

      it "should raise RuntimeError when not able to set the new log level" do
        read.stub(:read).and_return('EOEOEO PANIC!!!')
        kannel.should_receive(:open).and_return(read)

        lambda { kannel.set_log_level(1) }.should raise_error(RuntimeError)
      end
    end
  end # /Manager
end # /Kannel
