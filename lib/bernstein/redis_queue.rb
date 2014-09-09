require 'redis'

module Bernstein
  class RedisQueue
    include Persistence
    REQUEST_QUEUE = "webosc_queued_requests"
    # TODO make configurable
    KEY_EXPIRY = 300
    # TODO make configurable options
    @@redis = Redis.new

    def self.add_to_queue(message)
      @@redis.multi do
        @@redis.sadd REQUEST_QUEUE, message.id
        @@redis.setex message.id, KEY_EXPIRY, {'address' => message.address, 'args' => message.args}.to_json
        @@redis.setex status_key(message.id), KEY_EXPIRY, STATES[:queued]
      end
    end

    def self.request_status(id)
      # returns status of request by id
      @@redis.get status_key(id)
    end

    def self.queued_messages
      request_ids = @@redis.smembers REQUEST_QUEUE
      unless request_ids.empty?
        requests = @@redis.mget(request_ids).compact
        unless requests.empty?
          requests.map!{|r| Message.new(JSON.parse(r))}
        end
        if requests.size < request_ids.size
          #TODO
          clean_up_queue
        end
      end
      requests
    end

    def self.mark_as_sent(id)
      @@redis.multi do
        @@redis.srem REQUEST_QUEUE, id
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

    def clean_up_queue
      #TODO
    end
  end
end
