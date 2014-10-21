require 'bernstein/states'
require 'bernstein/redis_queue'
require 'bernstein/osc_connection'
require 'bernstein/message'
require 'bernstein/client'
require 'bernstein/server'
require 'yaml'

module Bernstein
  def self.configure_from_yaml!(file_path)
    configure!(YAML.load_file(file_path))
  end

  def self.configure!(options = {})
    RedisQueue.configure!(options[:redis_queue])
    OSCConnection.configure!(options[:osc_client])
    Server.configure!(options[:osc_server])
  end
end
