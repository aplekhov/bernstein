require 'redis'

module Bernstein
  class RedisQueue
    include Persistence
    QUEUE_SET = "bernstein_queued_messages"
    # TODO make configurable
    KEY_EXPIRY = 300
    # TODO make configurable options
    @@redis = Redis.new

    def self.add(message)
      @@redis.multi do
        @@redis.sadd QUEUE_SET, message.id
        @@redis.setex message.id, KEY_EXPIRY, {'address' => message.address, 'args' => message.args, 'id' => message.id}.to_json
        @@redis.setex status_key(message.id), KEY_EXPIRY, STATES[:queued]
      end
    end

    def self.status(id)
      # returns status of request by id
      @@redis.get status_key(id)
    end

    def self.queued_messages
      request_ids = @@redis.smembers QUEUE_SET
      unless request_ids.empty?
        requests = @@redis.mget(request_ids).compact
        unless requests.empty?
          requests.map!{|r| JSON.parse(r)}
          requests.map!{|r| Bernstein::Message.new(id: r['id'], address: r['address'], args: r['args'])} 
        end
        if requests.size < request_ids.size
          #TODO
          clean_up_queue
        end
      end
      requests
    end

    def self.clear
      @@redis.del QUEUE_SET
    end

    def self.mark_as_sent(id)
      @@redis.multi do
        @@redis.srem QUEUE_SET, id
        @@redis.set status_key(id), STATES[:sent]
      end
      @@redis.del id
    end

    def self.mark_as_awknowledged(id)
      @@redis.set status_key(id), STATES[:awked]
    end

    protected
    def self.status_key(id)
      "#{id}_status"
    end

    def self.clean_up_queue
      #TODO
    end
  end
end
