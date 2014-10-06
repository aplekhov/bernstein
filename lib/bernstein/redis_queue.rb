require 'redis'
require 'redis-namespace'

module Bernstein
  class RedisQueue
    include Persistence
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
      # returns status of request by id
      (@redis.get status_key(id)) || STATES[:not_yet_queued]
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

    def self.mark_as_sent(id)
      update_status(id, STATES[:sent]) do
        @redis.srem QUEUE_SET, id
      end
      @redis.del id
    end

    def self.mark_as_awknowledged(id)
      update_status id, STATES[:awked]
    end

    protected
    def self.status_key(id)
      "#{id}_status"
    end

    def self.update_status(id, status)
      if block_given?
        @redis.multi do
          yield
          @redis.set status_key(id), status
        end
      else
        @redis.set status_key(id), status
      end
    end

    def self.clean_up_queue(ids_to_remove)
      @redis.pipelined do
        ids_to_remove.each{|id| @redis.srem QUEUE_SET, id}
      end
    end
  end
end
