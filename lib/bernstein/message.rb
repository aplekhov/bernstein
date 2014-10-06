require 'ruby-osc'
require 'json'

module Bernstein
  class Message
    attr_reader :id, :osc_message
    @@persister = RedisQueue
    @@osc_connection = OSCConnection

    # OSC message could be a bundle
    def initialize(osc_message, id = nil)
      @osc_message = osc_message
      @id = id || new_id
      @is_saved = false
    end

    def self.build(address = '', *args)
      Message.new(OSC::Message.new(address, *args))
    end

    # only supports float arguments
    def self.build_from_string(message_string)
      address, args = parse_message_string(message_string)
      Message.new(OSC::Message.new(address, *args))
    end

    def self.deserialize(serialized_msg)
      serialized_msg = serialized_msg.split(',')
      id = serialized_msg.shift
      osc_message = OSC.decode(serialized_msg.join(','))
      Message.new osc_message, id
    end

    def serialize
      [@id,@osc_message.encode].join(',')
      #{:id => @id, :data => @osc_message.encode}.to_json
    end

    def self.get_status(id)
      @@persister.status(id)
    end

    def status
      @@persister.status(@id)
    end

    def self.get_queued_messages
      @@persister.queued_messages
    end

    def self.set_as_awknowledged(id)
      @@persister.mark_as_awknowledged(id)
    end

    def save!
      unless @is_saved
        @@persister.add(self)
        @is_saved = true
      end
    end

    def send!
      @@osc_connection.send_message self
      @@persister.mark_as_sent @id
    end

    def ==(other)
      (self.class == other.class) && (self.osc_message == other.osc_message) &&
        (self.id == other.id)
    end
    
    protected
    def new_id
      Time.now.to_f.to_s.delete('.')
    end

    def self.parse_message_string message_string
      message_array = message_string.split
      [message_array.shift, message_array.map{|arg| arg.to_f}]
    end
  end
end
