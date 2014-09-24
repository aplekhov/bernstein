require 'helper'

def redis_connection
  Bernstein::RedisQueue.instance_variable_get('@redis')
end

describe Bernstein::RedisQueue do
  before(:each) do
    @message = Bernstein::Message.build("/test/3 1 2.55 4")
  end

  describe "initialization and configuration" do
    after(:all){Bernstein::RedisQueue.configure!({redis:{}})}

    it "should pass redis options to initialize a new redis connection" do
      pending "fixing some rspec weirdness"
      redis_opts = {host: "10.0.1.1", port: 6380, db: 15}
      expect(Redis).to receive(:new)
      Bernstein::RedisQueue.configure!({key_expiry: 600, redis: redis_opts})
    end

    it "should be namespaced" do
      expect(redis_connection.class).to eq(Redis::Namespace)
    end
  end

  describe "adding a new message" do
    it "should serialize the message to json and add it to the proper sets" do
      Bernstein::RedisQueue.add(@message)
      data = JSON.parse(redis_connection.get(@message.id))
      expect(data['address']).to eq('/test/3')
      expect(data['args']).to eq([1.0, 2.55, 4])
      expect(redis_connection.smembers(Bernstein::RedisQueue::QUEUE_SET)).to include(@message.id)
    end
  end

  describe "expired messages" do
    before(:all) do
      @key_expiry = 1
      Bernstein::RedisQueue.configure! key_expiry: @key_expiry
    end

    it "should expire messages based on set expiry times" do
      Bernstein::RedisQueue.add(@message)
      expect(redis_connection.get(@message.id)).to_not be_nil
      sleep @key_expiry + 1
      expect(redis_connection.get(@message.id)).to be_nil
    end

    it "should clean up request_queue of unhandled expired messages" do
      Bernstein::RedisQueue.add(@message)
      expect(Bernstein::RedisQueue.queued_messages).to include(@message)
      sleep @key_expiry + 1
      @another_message = Bernstein::Message.build("/test/current 5 6 7")
      Bernstein::RedisQueue.add(@another_message)
      queued_messages = Bernstein::RedisQueue.queued_messages
      queue_set = redis_connection.smembers Bernstein::RedisQueue::QUEUE_SET
      expect(queued_messages).to_not include(@message)
      expect(queued_messages).to include(@another_message)
      expect(queue_set).to_not include(@message.id)
      expect(queue_set).to include(@another_message.id)
    end
  end

  describe "marking and requesting status" do
    it "should return not yet queued status for unknown messages" do
      expect(Bernstein::RedisQueue.status('123456')).to eq(Bernstein::Persistence::STATES[:not_yet_queued])
    end

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
