require 'spec_helper'

module Kannel
  module State
    describe ".bearerbox" do
      it "should return an instance of Kannel::State::Bearerbox" do
        Kannel::State.bearerbox('spec/support/').is_a?(Kannel::State::Bearerbox).should == true
      end
    end

    describe ".cache" do
      it "should return an instance of Kannel::State::Cache" do
        Kannel::State.cache('spec/support/cache.yml').is_a?(Kannel::State::Cache).should == true
      end
    end

    describe Bearerbox do
      let(:status) { Bearerbox.new('spec/support') }

      describe "#uptime=" do
        it "should convert the kannel uptime string to seconds" do
          status.uptime = '1d 8h 12m 5s'
          status.uptime.should == 115_925
        end
      end

      describe "#load" do
        it "should fetch the data from Kannel and then populate itself" do
          status.load
          status.status.should            == :running
          status.uptime.should            == 29_525
          status.messages_sent.should     == 416
          status.messages_queued.should   == 0
          status.messages_stored.should   == 0
          status.messages_received.should == 8
        end
      end
    end # /Bearerbox

    describe Cache do
      let(:cache) { Cache.new('spec/support/cache.yml') }
      describe "#new" do
        it "should not raise errors when instantiated with an accessible file" do
          lambda { Cache.new('spec/support/cache.yml') }.should_not raise_error
        end

        it "should raise ArgumentError when the file is not accessible" do
          lambda { Cache.new('spec/support/cache.yml-doesnt-exist') }.should raise_error(ArgumentError)
        end
      end

      describe "#[]=" do
        it "should set and return the set value" do
          cache[:uptime] = 300
          cache[:uptime].should == 300
        end

        it "should return the loaded value when only that is set" do
          cache.load
          cache[:uptime].should == 29_525
        end

        it "should return the new old value after load and the new after set" do
          cache.load
          cache[:messages_sent].should == 416
          cache[:messages_sent] = 500
          cache[:messages_sent].should == 500
        end
      end

      describe "#smsc" do
        it "should return a hash of all restarted SMS Centers with no arguments passed" do
          cache.load
          cache.smsc.should == {'modem0' => 2, 'modem1' => 1}
        end

        it "should return the number of restarts of a SMS Center when passed one in" do
          cache.load
          cache.smsc('modem0').should == 2
        end

        it "should return 0 when SMS Center has not been restarted" do
          cache.load
          cache.smsc('modem-1').should == 0
        end
      end

      describe "#increment_smsc" do
        it "should increment a previously restarted SMS Center" do
          cache.load
          cache.increment_smsc('modem0')
          cache.smsc('modem0').should == 3
        end

        it "should handle to increment two previously restarted SMS Centers" do
          cache.load
          cache.smsc('modem0').should == 2
          cache.smsc('modem1').should == 1
          cache.increment_smsc('modem0')
          cache.increment_smsc('modem1')
          cache.smsc('modem0').should == 3
          cache.smsc('modem1').should == 2
        end

        it "should set an unrestarted SMS Center to 1" do
          cache.load
          cache.smsc('modem-1').should == 0
          cache.increment_smsc('modem-1')
          cache.smsc('modem-1').should == 1
        end
      end

      describe "#save" do
        before do
          cache.load
          cache[:uptime] = 30_000
        end

        it "should return a hash when passed in an argument that evaluates true" do
          cache.save(:debug).is_a?(Hash).should == true
        end

        it "should save the new value instead of the old" do
          cache[:sent_messages] = 500
          cache.save(:debug)[:sent_messages].should == 500
        end

        it "should zero messages_sent on a new month" do
          cache[:current_month].should == 9
          cache[:last_updated] = Time.parse('2010-10-01 00:00')
          saved = cache.save(:debug)
          saved[:messages_sent].should == 0
          saved[:current_month].should == 10
        end

        it "should increment +stored_same_count+ when it is the same between updates" do
          cache[:stored_messages] = 1
          cache[:last_updated] = Time.parse('2010-09-20 00:00')
          cache[:stored_same_count].should == 0
          cache.save(:debug)[:stored_same_count].should == 1
        end

        it "should not increment +stored_same_count+ if old and new are both 0" do
          cache[:last_updated] = Time.parse('2010-09-20 00:00')
          cache.save(:debug)[:stored_same_count].should == 0
        end

        it "should clear SMSC restart cache when uptime is less than current uptime" do
          cache[:uptime] = 65
          saved = cache.save(:debug)
          saved[:uptime].should == 65
          saved[:smsc].empty?.should == true
        end
      end # /#save
    end # /Cache
  end # /State
end # /Kannel
