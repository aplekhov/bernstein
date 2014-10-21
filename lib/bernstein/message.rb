require 'ruby-osc'
require 'json'

module Bernstein
  class Message
    attr_reader :id, :osc_message
    @@persister = RedisQueue
    @@osc_connection = OSCConnection

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
      data = JSON.parse(serialized_msg)
      Message.new OSC::Message.new(data['address'], *data['args']), data['id']
    end

    def serialize
      {'id' => @id, 'address' => @osc_message.address, 'args' => @osc_message.args}.to_json
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

    def self.set_as_sent!(id)
      @@persister.mark_as_sent(id)
    end

    def save!
      unless @is_saved
        @@persister.add(self)
        @is_saved = true
      end
    end

    def send!(expect_awk = true)
      @@osc_connection.send_message self
      @@persister.dequeue @id, !expect_awk
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
