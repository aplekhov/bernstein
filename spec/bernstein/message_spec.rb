require 'helper'
require 'ruby-osc'

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

  def dequeue(id, mark_as_sent = false)
    message = @queue.find{|m| m.id == id}
    if !message.nil?
      @message_states[message] = (mark_as_sent ? :sent : :sending)
      @sent_messages << message
      @queue.delete(message)
    end
  end

  def mark_as_sent(id)
    message = @message_states.keys.find{|m| m.id == id}
    @message_states[message] = :sent unless message.nil?
  end

  def status(id)
    message = @message_states.keys.find{|m| m.id == id}
    Bernstein::States::STATES[@message_states[message]]
  end

  def clear
    @queue.clear
    @sent_messages.clear
    @message_states.clear
  end
end

class DummyOSCConnection
  attr_accessor :fail_send, :sent_messages, :sent_ids
  def initialize
    @fail_send, @sent_messages, @sent_ids = false, [], []
  end

  def send_message message, with_message_id = true
    if @fail_send
      throw "something went wrong"
    else
      @sent_messages << message
      @sent_ids << message.id if with_message_id
    end
  end
end

describe Bernstein::Message do
  subject { Bernstein::Message }

  before(:all) do
    @mock_queue = DummyPersister.new
    @mock_osc_connection = DummyOSCConnection.new
    @real_persister = Bernstein::Message.class_variable_get('@@persister')
    @real_osc_connection = Bernstein::Message.class_variable_get('@@osc_connection')
    Bernstein::Message.class_variable_set('@@persister', @mock_queue)
    Bernstein::Message.class_variable_set('@@osc_connection', @mock_osc_connection)
  end

  after(:all) do
    Bernstein::Message.class_variable_set('@@persister', @real_persister)
    Bernstein::Message.class_variable_set('@@osc_connection', @real_osc_connection)
  end

  before(:each) do
    @mock_queue.clear
    @message = Bernstein::Message.build_from_string("/test 1 2 3")  
  end

  describe "building a new message" do
    it "should be able to be built from a message string and turn all parameters into floats" do
      address = "/test/this/out"
      args = ['1', '2', '3.5']
      message = subject.build_from_string("#{address} #{args.join(' ')}")
      expect(message.osc_message.address).to eq(address)
      expect(message.osc_message.args).to eq(args.map{|a| a.to_f})
    end

    it "should be able to built from address and args, preserving types" do
      address = "/test/this/out"
      args = [5, 'pizza', 9.9, 2.0]
      message = subject.build(address,*args)
      expect(message.osc_message.address).to eq(address)
      expect(message.osc_message.args).to eq(args)
    end

    it "should be able to be built from an already built osc message" do
      msg = OSC::Message.new('/hi/msg','2',4)
      message1 = subject.new(msg)
      expect(message1.osc_message).to eq(msg)
    end

    it "should return a unique id" do
      messages = []
      5.times {|i| messages << subject.build_from_string("/test #{i}")}
      messages.each do |message| 
        expect(message.id).to_not be_nil
        (messages - [message]).each{|other_message| expect(other_message.id).to_not eq(message.id)}
      end
    end

    it "should be able to be built with a set id" do
      address = "/test/this/out"
      args = ['1', '2', '3']
      id = "456"
      osc_msg = OSC::Message.new(address, *args)
      message = subject.new osc_msg, id
      expect(message.id).to eq(id)
      expect(message.osc_message.address).to eq(address)
      expect(message.osc_message.args).to eq(args)
    end

    it "should be equal to another message with the same id, args and address" do
      message1 = subject.build_from_string("/test 1 2 3") 
      message2 = subject.new(OSC::Message.new("/test", 1,2,3), message1.id)
      message3 = subject.new(message2.osc_message, '999')
      expect(message1).to eq(message2)
      expect(message1).to_not eq(message3)
    end
  end

  describe "serialization" do
    it "should serialize and deserialize the osc message and id" do
      @message = subject.build_from_string("/test 1 2 3.2345")  
      serialized_msg = @message.serialize
      expect(@message).to eq(subject.deserialize(serialized_msg))
    end

    it "should handle float, integer and string arguments" do
      @message = subject.build("/test", 3.4567, 10, 'a_string')
      serialized_msg = @message.serialize
      expect(@message).to eq(subject.deserialize(serialized_msg))
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

    after(:each) do
      @mock_osc_connection.fail_send = false
    end

    it "should send the message and message id on the OSC connection and remove from queue" do
      @message.send!
      expect(@mock_osc_connection.sent_messages).to include(@message)
      expect(@mock_osc_connection.sent_ids).to include(@message.id)
      expect(@mock_queue.sent_messages).to include(@message)
    end

    it "should not mark the message as sent on the queue if there is an error" do
      @mock_osc_connection.fail_send = true
      @message.send rescue
      expect(@mock_queue.sent_messages).to_not include(@message)
      expect(@mock_osc_connection.sent_messages).to_not include(@message)
      expect(@mock_osc_connection.sent_ids).to_not include(@message.id)
    end

    it "should send the message and mark as sent and not ask to send message id along" do
      @message.send!(false)
      expect_state(@message.status, :sent)
      expect(@mock_osc_connection.sent_messages).to include(@message)
      expect(@mock_osc_connection.sent_ids).to_not include(@message.id)
    end
  end

  describe "querying status" do
    before(:each) do
      @message.save!
    end

    it "should return the current status for a message object" do
      expect_state(@message.status, :queued)
      @message.send!
      expect_state(@message.status, :sending)
      @mock_queue.mark_as_sent(@message.id)
      expect_state(@message.status, :sent)
    end

    it "should return the current status by message id" do
      expect_state(subject.get_status(@message.id), :queued)
      @message.send!(false)
      expect_state(subject.get_status(@message.id), :sent)
    end
  end

  describe "getting queued messages" do
    it "should return all queued messages" do
      @message.save!
      @message2 = subject.build_from_string("/test/2 4 5 6")
      @message2.save!
      expect(subject.get_queued_messages).to eq([@message, @message2])
    end
  end
end
