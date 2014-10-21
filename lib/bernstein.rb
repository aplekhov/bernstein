require 'bernstein/states'
require 'bernstein/redis_queue'
require 'bernstein/osc_connection'
require 'bernstein/message'
require 'bernstein/client'
require 'bernstein/server'

module Bernstein
  def self.configure!(options = {})
    RedisQueue.configure!(options[:redis_queue])
    OSCConnection.configure!(options[:osc_client])
    Server.configure!(options[:osc_server])
  end
end
