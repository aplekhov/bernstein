require 'helper'

class DummyPersister
  attr_accessor :queue, :sent_messages
  def initialize
    @queue, @sent_messages = [],[]
  end

  def add(message)
    @queue << message
  end

  def mark_as_sent(message)
    @sent_messages << message
  end

  def clear_all
    @queue.clear
    @sent_messages.clear
  end
end

class DummyOSCConnection
  attr_accessor :fail_send, :sent_messages
  def initialize
    @fail_send, @sent_messages = false, []
  end

  def send message
    if @fail_send
      throw "something went wrong"
    else
      @sent_messages << message
    end
  end
end

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

    it "should be equal to another message with the same id, args and address" do
      message1 = Bernstein::Message.build("/test 1 2 3") 
      message2 = Bernstein::Message.new(id: message1.id, address: message1.address, args: message1.args)
      message3 = Bernstein::Message.new(id: '123', address: message1.address, args: message1.args)
      expect(message1).to eq(message2)
      expect(message1).to_not eq(message3)
    end
  end

  describe "saving a message" do
    before(:all) do
      @mock_queue = DummyPersister.new
      Bernstein::Message.class_variable_set('@@persister', @mock_queue)
    end

    before(:each) do
      @mock_queue.clear_all
      @message = Bernstein::Message.build("/test 1 2 3")  
    end

    it "should add message onto the queue upon save" do
      @message.save!
      expect(@mock_queue.queue).to include(@message)
    end

    it "should not be able to add the same message onto the queue again" do
      @message.save!
      expect{@message.save!}.to_not change(@mock_queue.queue, :size)
    end
  end

  describe "sending a message" do
    before(:all) do
      @mock_queue = DummyPersister.new
      @mock_osc_connection = DummyOSCConnection.new
      Bernstein::Message.class_variable_set('@@persister', @mock_queue)
      Bernstein::Message.class_variable_set('@@osc_connection', @mock_osc_connection)
    end

    before(:each) do
      @mock_queue.clear_all
      @message = Bernstein::Message.build("/test 1 2 3")  
    end

    it "should send the message on the OSC connection and mark as sent on the queue" do
      @message.send!
      expect(@mock_osc_connection.sent_messages).to include(@message)
      expect(@mock_queue.sent_messages).to include(@message)
    end

    it "should not mark the message as sent on the queue if there is an error" do
      @mock_osc_connection.fail_send = true
      @message.send rescue
      expect(@mock_queue.sent_messages).to_not include(@message)
    end
  end
end
