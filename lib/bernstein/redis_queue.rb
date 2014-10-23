require 'redis'
require 'redis-namespace'

module Bernstein
  class RedisQueue
    include States

    QUEUE_SET = "queued_messages"
    @options = {key_expiry: 300, redis: {}}

    def self.configure!(options = {})
      @options.merge!(options || {})
      @redis = Redis::Namespace.new(:bernstein, :redis => Redis.new(@options[:redis]))
    end

    def self.add(message)
      @redis.multi do
        @redis.sadd QUEUE_SET, message.id
        @redis.setex message.id, @options[:key_expiry], message.serialize
        @redis.setex status_key(message.id), @options[:key_expiry], STATES[:queued]
      end
    end

    def self.status(id)
      @redis.get(status_key(id)) || STATES[:not_yet_queued]
    end

    def self.queued_messages
      queued_message_ids = @redis.smembers QUEUE_SET
      messages = []
      unless queued_message_ids.empty?
        messages = @redis.mget(queued_message_ids).compact
        unless messages.empty?
          messages.map!{|m| Message.deserialize(m)} 
        end
        if messages.size < queued_message_ids.size
          clean_up_queue(queued_message_ids - messages.map{|m| m.id})
        end
      end
      messages
    end

    def self.clear
      @redis.del QUEUE_SET
    end

    def self.dequeue(id, mark_as_sent = false)
      remove_and_change_status(id, (mark_as_sent ? STATES[:sent] : STATES[:sending]))
    end

    def self.mark_as_sent(id)
      set_status(id, STATES[:sent])
    end

    private
    def self.status_key(id)
      "#{id}_status"
    end

    def self.remove_and_change_status(id, status)
      remove(id){ set_status(id, status) }
    end

    def self.set_status(id, status)
      @redis.setex status_key(id), @options[:key_expiry], status
    end

    def self.remove(id)
      if block_given?
        @redis.multi do
          @redis.srem QUEUE_SET, id
          yield
        end
      else
        @redis.srem QUEUE_SET, id
      end
      @redis.del id
    end

    def self.clean_up_queue(ids_to_remove)
      @redis.pipelined do
        ids_to_remove.each{|id| @redis.srem QUEUE_SET, id}
      end
    end
  end
end
