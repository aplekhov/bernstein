require 'rubygems'
require 'redis'
require 'ruby-osc'
require 'json'

require File.join([File.dirname(__FILE__), 'handlers', 'test_handler'])
require File.join([File.dirname(__FILE__), 'handlers', 'test2_handler'])

# ISIS = Interactive Sound Installation System?
module Isis
  include OSC 

  RedisClient = Redis.new

  def new_id
    # generate new unique id
    # TODO improve this to make it more unique and shorter
    Time.now.to_i.to_s
  end

  def save_new_request(handler_name, parameters = {})
    # put request in queue for deferred processing
    # returns id to track
    id = new_id
    data = {'handler' => handler_name, 'id' => id, 'params' => parameters}
    RedisClient.multi do
      RedisClient.sadd "queued_requests", id
      RedisClient.setex id, 300, data.to_json
      RedisClient.setex "#{id}_status", 300, "queued"
    end
    return id
  end

  def request_status(id)
    # returns status of request by id
    RedisClient.get "#{id}_status"
  end

  def process_queued_requests
    requests = RedisClient.smembers "queued_requests"
    @handlers ||= {}
    unless requests.empty?
      requests = RedisClient.mget(requests).compact
      # TODO: clean up expired queued requests 
      unless requests.empty?
        requests.map!{|r| JSON.parse(r)}
        requests_by_handler = requests.group_by{|r| r['handler']}
        requests_by_handler.keys.each do |handler_name|
          handler = @handlers[handler_name]
          if handler.nil?
            handler_class = Object.const_get handler_name
            handler = handler_class.new
            @handlers[handler_name] = handler
          end
          handler.process_requests(requests_by_handler[handler_name], self)
        end
      end
    end
  end

  # called by handlers #####
  def merge_requests(ids, method, *parameters)
    merged_id = new_id
    # TODO try block?
    send_osc(merged_id, method, *parameters)
    RedisClient.multi do
      RedisClient.srem "queued_requests", ids
      RedisClient.setex "#{merged_id}_status", 300, "sent"
      RedisClient.mset ids.map{|id| ["#{id}_status", "merged_#{merged_id}"]}.flatten
    end
    RedisClient.del ids
  end

  def send_request(id, method, *parameters)
    # TODO try block?
    send_osc(id,method, *parameters)
    RedisClient.multi do
      RedisClient.srem "queued_requests", id
      RedisClient.set "#{id}_status", "sent"
    end
    RedisClient.del id
  end

  def send_osc(id, method, *parameters)
    # TODO make this configurable
    # TODO allow a handler to be able to send a multi-message bundle
    client = Client.new 8000
    client.send Bundle.new(nil, Message.new(method,*parameters), Message.new('/request_id', id))
  end

  #############################
  # TODO: setup server here?#
  def handle_request_awknowledgement(id)
    RedisClient.set "#{id}_status", "processed"
  end
end
