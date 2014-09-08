require 'helper'

describe Bernstein::Message do
  describe "building a new message" do
    it "should be able to be built from a message string" do
      address = "/test/this/out"
      args = ['1', '2', '3']
      message = Bernstein::Message.build("#{address} #{args.join(' ')}")
      expect(message.address).to eq(address)
      expect(message.args).to eq(args)
    end

    it "should return a unique id" do
      messages = []
      5.times {|i| messages << Bernstein::Message.build("/test #{i}")}
      messages.each do |message| 
        expect(message.id).to_not be_nil
        (messages - [message]).each{|other_message| expect(other_message.id).to_not eq(message.id)}
      end
    end

    it "should be able to be built from an address string and args array" do
      address = "/test/this/out"
      args = ['1', '2', '3']
      id = "456"
      message = Bernstein::Message.new id: id, address: address, args: args
      expect(message.id).to eq(id)
      expect(message.address).to eq(address)
      expect(message.args).to eq(args)
    end
  end

  describe "saving a message" do
    before(:each) do
      @message = Bernstein::Message.build("/test 1 2 3")  
    end

    it "should add message onto the queue upon save" do
      expect(Bernstein::Persistence).to receive(:add_to_queue).with(@message)
      @message.save!
    end

    it "should not be able to add the same message onto the queue again" do
      expect(Bernstein::Persistence).to receive(:add_to_queue).with(@message).once
      @message.save!
      @message.save!
    end
  end

  describe "sending a message" do
    it "should send the message on the OSC connection and mark as sent on the queue" do
      #pending("refactoring osc connection")
      #@message = Bernstein::Message.build("/test 1 2 3")  
      #expect(Bernstein::Persistence).to receive(:mark_as_sent).with(@message).once
      #@message.send!
    end
  end
end
