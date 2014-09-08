module Bernstein
  class Message
    attr_reader :id, :address, :args

    def initialize options = {}
      @id, @address, @args = options[:id], options[:address], options[:args]
      @is_saved = options[:is_saved] || false
    end

    def self.build message_string
      address, args = parse_message_string(message_string)
      Message.new id: new_id, address: address, args: args
    end

    def save!
      unless @is_saved
        Persistence.add_to_queue(self)
        @is_saved = true
      end
    end

    def send!
      #OSCConnection.send(@address, @args)
      Persistence.mark_as_sent(self)
    end

    protected
    def self.new_id
      Time.now.to_f.to_s.delete('.')
    end

    def self.parse_message_string message_string
      message_array = message_string.split
      [message_array.shift, message_array]
    end
  end
end
