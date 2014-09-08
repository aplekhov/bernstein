module Bernstein
  class Persistence
    #TODO define states here
    REQUEST_QUEUE = "webosc_queued_requests"
    KEY_EXPIRY = 300
    QUEUED_STATE = 'queued'
    SENT_STATE = 'sent'
    AWK_STATE = 'awknowledged'

    def self.add_to_queue(message)
      RedisClient.multi do
        RedisClient.sadd REQUEST_QUEUE, message.id
        RedisClient.setex message.id, KEY_EXPIRY, {'address' => message.address, 'args' => message.args}.to_json
        RedisClient.setex status_key(message.id), KEY_EXPIRY, QUEUED_STATE
      end
    end

    def self.request_status(id)
      # returns status of request by id
      RedisClient.get status_key(id)
    end

    def self.queued_messages
      request_ids = RedisClient.smembers REQUEST_QUEUE
      unless request_ids.empty?
        requests = RedisClient.mget(request_ids).compact
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
      RedisClient.multi do
        RedisClient.srem REQUEST_QUEUE, id
        RedisClient.set status_key(id), SENT_STATE
      end
      RedisClient.del id
    end

    def self.mark_as_awknowledged(id)
      RedisClient.set status_key(id), AWK_STATE
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
