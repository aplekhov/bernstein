require 'helper'

describe Bernstein::Client do
  subject { Bernstein::Client }

  describe "sending a message" do
    it "should build the message object and return its id" do
      id = subject.send_message_by_string("/synths/4/chord/notes 25 30 10")
      expect(id).to_not be_nil
      queued_messages = Bernstein::Message.get_queued_messages
      message = queued_messages.find{|m| m.id == id}
      expect(message).to_not be_nil
      expect(message.osc_message.address).to eq("/synths/4/chord/notes")
      expect(message.osc_message.args).to eq([25.0, 30.0, 10.0])
    end

    it "should accept arguments to build the message" do
      id = subject.send_message("/synths/4/parameters", 20, 34.2, 'squarewave')
      expect(id).to_not be_nil
      queued_messages = Bernstein::Message.get_queued_messages
      message = queued_messages.find{|m| m.id == id}
      expect(message).to_not be_nil
      expect(message.osc_message.address).to eq("/synths/4/parameters")
      expect(message.osc_message.args).to eq([20, 34.2, 'squarewave'])
    end
  end

  describe "querying a message's status by id" do
    it "should return the current status or not yet queued" do
      id = subject.send_message("/synths/4/chord/notes 25 30 10")
      expect_state(subject.message_status(id), :queued)
      expect_state(subject.message_status('123'), :not_yet_queued)
    end
  end
end
