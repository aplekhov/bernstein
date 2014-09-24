require 'ruby-osc'

module Bernstein
  class OSCConnection
    include OSC
  
    @options = {port: 8000, host: '127.0.0.1', send_message_ids: true}
    
    def self.configure!(options = {})
      @options.merge!(options || {})
      @connection = OSC::Client.new @options[:port], @options[:host]
    end

    def self.send_message(message)
      osc_message = OSC::Message.new(message.address,*message.args)
      osc_message = OSC::Bundle.new(nil, osc_message, OSC::Message.new('/message_id', message.id)) if @options[:send_message_ids]
      @connection.send osc_message
    end
  end
end
