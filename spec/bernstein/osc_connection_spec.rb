require 'helper'

def current_client
  Bernstein::OSCConnection.instance_variable_get('@connection')
end

describe Bernstein::OSCConnection do
  describe "configuring" do
    it "should instantiate a new osc client based on the port and host that was given" do
      expect(OSC::Client).to receive(:new).with(9000, '10.10.10.1')
      Bernstein::OSCConnection.configure!({port: 9000, host: '10.10.10.1'})
    end
  end
  
  describe "sending a message" do
    it "should create a new osc message from the passed in message and call send on the client" do
      Bernstein::OSCConnection.configure!({port: 9000, host: '10.10.10.1'})
      expect(OSC::Message).to receive(:new).with('/test', 1.0,2.0,3.0).and_return("mock")
      message1 = Bernstein::Message.build_from_string("/test 1 2 3")
      expect(current_client).to receive(:send).with("mock")
      Bernstein::OSCConnection.send_message(message1, false)
    end

    it "should send a bundle when asked to send message id" do
      Bernstein::OSCConnection.configure!({port: 9000, host: '10.10.10.1'})
      message1 = Bernstein::Message.build_from_string("/test 1 2 3")
      expect(current_client).to receive(:send).with(kind_of(OSC::Bundle))
      Bernstein::OSCConnection.send_message(message1, true)
    end
  end
end
