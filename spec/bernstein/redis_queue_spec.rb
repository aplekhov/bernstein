require 'helper'

def redis_connection
  Bernstein::RedisQueue.instance_variable_get('@redis')
end

def redis_queue
  redis_connection.smembers(Bernstein::RedisQueue::QUEUE_SET)
end

describe Bernstein::RedisQueue do
  subject { Bernstein::RedisQueue }

  before(:each) do
    @message = Bernstein::Message.build_from_string("/test/3 1 2.55 4")
  end

  describe "initialization and configuration" do
    after(:all){Bernstein::RedisQueue.configure!({redis:{}})}

    it "should pass redis options to initialize a new redis connection" do
      redis_opts = {host: "10.0.1.1", port: 6380, db: 15}
      expect(Redis).to receive(:new).with(redis_opts).and_call_original
      Bernstein::RedisQueue.configure!({key_expiry: 600, redis: redis_opts})
    end

    it "should be namespaced" do
      expect(redis_connection.class).to eq(Redis::Namespace)
    end
  end

  describe "adding a new message" do
    it "should serialize the message and add it to the proper sets" do
      subject.add(@message)
      data = redis_connection.get(@message.id)
      expect(Bernstein::Message.deserialize(data)).to eq(@message)
      expect(redis_queue).to include(@message.id)
    end
  end

  describe "expired messages" do
    before(:all) do
      @key_expiry = 1
      Bernstein::RedisQueue.configure! key_expiry: @key_expiry
    end

    it "should expire messages based on set expiry times" do
      subject.add(@message)
      expect(redis_connection.get(@message.id)).to_not be_nil
      sleep @key_expiry + 1
      expect(redis_connection.get(@message.id)).to be_nil
    end

    it "should clean up request_queue of unhandled expired messages" do
      subject.add(@message)
      expect(subject.queued_messages).to include(@message)
      sleep @key_expiry + 1
      @another_message = Bernstein::Message.build_from_string("/test/current 5 6 7")
      subject.add(@another_message)
      queued_messages = subject.queued_messages
      queue_set = redis_queue
      expect(queued_messages).to_not include(@message)
      expect(queued_messages).to include(@another_message)
      expect(queue_set).to_not include(@message.id)
      expect(queue_set).to include(@another_message.id)
    end
  end

  describe "marking and requesting status" do
    it "should return not yet sent queued for unknown messages" do
      expect_state(subject.status('123456'), :not_yet_queued)
    end

    it "should set new messages' status to queued" do
      subject.add(@message)
      expect_state(subject.status(@message.id), :queued)
    end

    it "should mark a message as sent" do
      subject.add(@message)
      subject.mark_as_sent(@message.id)
      expect_state(subject.status(@message.id), :sent)
    end

    it "should dequeue messages and set them to sending state by default" do
      subject.add(@message)
      subject.dequeue(@message.id)
      expect_state(subject.status(@message.id), :sending)
      expect(redis_queue).to_not include(@message.id)
    end

    it "should dequeue messages and set their state straight to sent" do
      subject.add(@message)
      subject.dequeue(@message.id, true)
      expect_state(subject.status(@message.id), :sent)
      expect(redis_queue).to_not include(@message.id)
    end
  end
  
  describe "getting queued messages" do
    it "should pull queued messages and deserialize them" do
      subject.clear
      message = Bernstein::Message.build_from_string("/test/1 1")
      message2 = Bernstein::Message.build_from_string("/test/2 1 2")
      message3 = Bernstein::Message.build_from_string("/test/3 1 2 3")
      messages = [message, message2, message3]
      messages.each{|m| subject.add(m)}
      expect(subject.queued_messages.sort{|a,b| a.id <=> b.id}).to eq(messages.sort{|a,b| a.id <=> b.id})
    end
  end
end
