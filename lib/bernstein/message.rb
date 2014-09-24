module Bernstein
  class Message
    attr_reader :id, :address, :args
    @@persister = RedisQueue
    @@osc_connection = OSCConnection

    def initialize options = {}
      @id, @address, @args = options[:id], options[:address], options[:args]
      @is_saved = options[:is_saved] || false
    end

    def self.build message_string
      address, args = parse_message_string(message_string)
      Message.new id: new_id, address: address, args: args
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
      (self.id == other.id) && (self.address == other.address) &&
        (self.args == other.args)
    end
    
    protected
    def self.new_id
      Time.now.to_f.to_s.delete('.')
    end

    def self.parse_message_string message_string
      message_array = message_string.split
      [message_array.shift, message_array.map{|arg| arg.to_f}]
    end
  end
end
