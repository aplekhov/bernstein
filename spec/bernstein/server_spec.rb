require 'helper'
require 'ruby-osc'
require 'eventmachine'

describe Bernstein::Server do
  describe "initialization and configuration" do
    it "should pass options to initialize a new OSC server" do
      opts = {port: 9004, host: '127.0.0.1'}
      expect(OSC::Server).to receive(:new).with(opts[:port], opts[:host]).and_call_original
      Bernstein::Server.configure!(opts)
      Bernstein::Server.start do
        Bernstein::Server.stop
        EventMachine.stop_event_loop 
      end
    end
  end

  describe "processing queued messages" do
    before(:each) do
      connection = Bernstein::Message.class_variable_get('@@osc_connection')
      allow(connection).to receive(:send_message)
      Bernstein::RedisQueue.clear
      @message = Bernstein::Client.send_message_by_string("/test/1 1")
      @message2 = Bernstein::Client.send_message_by_string("/test/2 1 2")
      @message3 = Bernstein::Client.send_message_by_string("/test/3 1 2 3")
      [@message, @message2, @message3].each do |message_id|
        expect_state(Bernstein::Client.message_status(message_id), :queued)
      end
    end


    it "should call send on all queued messages" do
      Bernstein::Server.configure!({poll_interval:1, require_awks:true})
      Bernstein::Server.start do
        EventMachine.add_timer 4 do
          Bernstein::Server.stop
          EventMachine.stop_event_loop
        end
      end
      [@message, @message2, @message3].each do |message_id|
        expect_state(Bernstein::Client.message_status(message_id), :sending)
      end
    end
  end

  describe "awks" do
    before(:each) do
      connection = Bernstein::Message.class_variable_get('@@osc_connection')
      allow(connection).to receive(:send_message)
      Bernstein::RedisQueue.clear
      @message_id = Bernstein::Client.send_message_by_string("/test/1 1")
      expect_state(Bernstein::Client.message_status(@message_id), :queued)
    end

    it "should listen for awks and set messages with corresponding ids to sent if configured" do
      Bernstein::Server.configure!({port: 9090, host: '127.0.0.1', poll_interval: 1, require_awks: true})
      Bernstein::Server.start do
        client = OSC::Client.new 9090
        EventMachine.add_timer 2 do
          expect_state(Bernstein::Client.message_status(@message_id), :sending)
        end
        EventMachine.add_timer 3 do
          client.send OSC::Message.new('/awk_id', @message_id)
        end
        EventMachine.add_timer 4 do
          Bernstein::Server.stop
          EventMachine.stop_event_loop
        end
      end
      expect_state(Bernstein::Client.message_status(@message_id), :sent)
    end

    it "should not listen for awks and set messages directly to sent if configured" do
      Bernstein::Server.configure!({port: 9090, host: '127.0.0.1', require_awks: false, poll_interval: 1})
      Bernstein::Server.start do
        client = OSC::Client.new 9090
        EventMachine.add_timer 2 do
          expect_state(Bernstein::Client.message_status(@message_id), :sent)
        end
        EventMachine.add_timer 3 do
          client.send OSC::Message.new('/awk_id', @message_id)
        end
        EventMachine.add_timer 4 do
          Bernstein::Server.stop
          EventMachine.stop_event_loop
        end
      end
      expect_state(Bernstein::Client.message_status(@message_id), :sent)
    end
  end
end
