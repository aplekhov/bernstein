require 'helper'

def redis_connection
  Bernstein::RedisQueue.class_variable_get('@@redis')
end

describe Bernstein::RedisQueue do
  describe "configuration" do
    it "should load configuration from file"
  end

  describe "adding a new message" do
    it "should serialize the message to json and add it to the proper sets" do
      message = Bernstein::Message.build("/test/3 one two three")
      Bernstein::RedisQueue.add(message)
      data = JSON.parse(redis_connection.get(message.id))
      expect(data['address']).to eq('/test/3')
      expect(data['args']).to eq(['one', 'two', 'three'])
      expect(redis_connection.smembers(Bernstein::RedisQueue::QUEUE_SET)).to include(message.id)
    end
  end

  describe "expired messages" do
    it "should expire messages based on set expiry times"
    it "should clean up request_queue of expired messages"
  end

  describe "marking and requesting status" do
    before(:each){@message = Bernstein::Message.build("/test/3 one two three")}
    it "should set new messages' status to queued" do
      Bernstein::RedisQueue.add(@message)
      expect(Bernstein::RedisQueue.status(@message.id)).to eq(Bernstein::Persistence::STATES[:queued])
    end

    it "should mark and store awknowledged message states" do
      Bernstein::RedisQueue.add(@message)
      Bernstein::RedisQueue.mark_as_awknowledged(@message.id)
      expect(Bernstein::RedisQueue.status(@message.id)).to eq(Bernstein::Persistence::STATES[:awked])
    end

    it "should mark sent messages and remove them from queue" do
      Bernstein::RedisQueue.add(@message)
      Bernstein::RedisQueue.mark_as_sent(@message.id)
      expect(Bernstein::RedisQueue.status(@message.id)).to eq(Bernstein::Persistence::STATES[:sent])
      expect(redis_connection.smembers(Bernstein::RedisQueue::QUEUE_SET)).to_not include(@message.id)
    end
  end
  
  describe "getting queued messages" do
    it "should pull queued messages and deserialize them" do
      Bernstein::RedisQueue.clear
      message = Bernstein::Message.build("/test/1 one")
      message2 = Bernstein::Message.build("/test/2 one two")
      message3 = Bernstein::Message.build("/test/3 one two three")
      messages = [message, message2, message3]
      messages.each{|m| Bernstein::RedisQueue.add(m)}
      expect(Bernstein::RedisQueue.queued_messages.sort{|a,b| a.id <=> b.id}).to eq(messages.sort{|a,b| a.id <=> b.id})
    end
  end
end
