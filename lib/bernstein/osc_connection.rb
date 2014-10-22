require 'ruby-osc'

module Bernstein
  class OSCConnection
    include OSC
  
    @options = {port: 8000, host: '127.0.0.1'}
    
    def self.configure!(options = {})
      @options.merge!(options || {})
      @connection = OSC::Client.new @options[:port], @options[:host]
    end

    def self.send_message(message, with_message_id = true)
      osc_message = message.osc_message
      osc_message = OSC::Bundle.new(nil, osc_message, OSC::Message.new('/message_id', message.id)) if with_message_id
      @connection.send osc_message
    end
  end
end
