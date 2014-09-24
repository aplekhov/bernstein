require 'helper'

class DummyPersister
  attr_accessor :queue, :sent_messages, :message_states
  def initialize
    @queue, @sent_messages, @message_states = [],[], {}
  end

  def add(message)
    @queue << message
    @message_states[message] = :queued
  end

  def queued_messages
    @queue
  end

  def mark_as_sent(id)
    message = @queue.find{|m| m.id == id}
    if !message.nil?
      @message_states[message] = :sent
      @sent_messages << message
      @queue.delete(message)
    end
  end

  def mark_as_awknowledged(id)
    message = @message_states.keys.find{|m| m.id == id}
    @message_states[message] = :awked unless message.nil?
  end

  def status(id)
    message = @message_states.keys.find{|m| m.id == id}
    Bernstein::Persistence::STATES[@message_states[message]]
  end

  def clear
    @queue.clear
    @sent_messages.clear
    @message_states.clear
  end
end

class DummyOSCConnection
  attr_accessor :fail_send, :sent_messages
  def initialize
    @fail_send, @sent_messages = false, []
  end

  def send_message message
    if @fail_send
      throw "something went wrong"
    else
      @sent_messages << message
    end
  end
end

describe Bernstein::Message do
  before(:all) do
    @mock_queue = DummyPersister.new
    @mock_osc_connection = DummyOSCConnection.new
    Bernstein::Message.class_variable_set('@@persister', @mock_queue)
    Bernstein::Message.class_variable_set('@@osc_connection', @mock_osc_connection)
  end

  before(:each) do
    @mock_queue.clear
    @message = Bernstein::Message.build("/test 1 2 3")  
  end

  describe "building a new message" do
    it "should be able to be built from a message string" do
      address = "/test/this/out"
      args = ['1', '2', '3']
      message = Bernstein::Message.build("#{address} #{args.join(' ')}")
      expect(message.address).to eq(address)
      expect(message.args).to eq(args.map{|a| a.to_f})
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
    before(:each) do
      @message.save!
    end

    after(:all) do
      @mock_osc_connection.fail_send = false
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

  describe "querying status" do
    before(:each) do
      @message.save!
    end

    it "should return the current status for a message object" do
      expect(@message.status).to eq(Bernstein::Persistence::STATES[:queued])
      @message.send!
      expect(@message.status).to eq(Bernstein::Persistence::STATES[:sent])
      @mock_queue.mark_as_awknowledged(@message.id)
      expect(@message.status).to eq(Bernstein::Persistence::STATES[:awked])
    end

    it "should return the current status by message id" do
      expect(Bernstein::Message.get_status(@message.id)).to eq(Bernstein::Persistence::STATES[:queued])
      @message.send!
      expect(Bernstein::Message.get_status(@message.id)).to eq(Bernstein::Persistence::STATES[:sent])
    end
  end

  describe "getting queued messages" do
    it "should return all queued messages" do
      @message.save!
      @message2 = Bernstein::Message.build("/test/2 4 5 6")
      @message2.save!
      expect(Bernstein::Message.get_queued_messages).to eq([@message, @message2])
    end
  end

  describe "handling awks" do
    it "should set the message status to awknowledged" do
      @message.save!
      @message.send!
      Bernstein::Message.set_as_awknowledged(@message.id)
      expect(Bernstein::Message.get_status(@message.id)).to eq(Bernstein::Persistence::STATES[:awked])
      expect(@message.status).to eq(Bernstein::Persistence::STATES[:awked])
    end
  end
end
