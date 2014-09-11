require 'rubygems'

require 'bernstein/persistence'
require 'bernstein/redis_queue'
require 'bernstein/osc_connection'
require 'bernstein/message'
require 'bernstein/client'
require 'bernstein/server'


#TODO forget about handlers for now
#require File.join([File.dirname(__FILE__), 'handlers', 'test_handler'])
#require File.join([File.dirname(__FILE__), 'handlers', 'test2_handler'])

module Bernstein
##################################### old code!

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
end
