module Bernstein
  class Message
    attr_accessor :id, :address, :args

    #TODO make second constructor for building messages from redis
    def initialize message_string = ''
      @id = new_id
      @address, @args = parse_message_string(message_string)
    end

    def save!
      Persistence.add_to_queue(@id, {'address' => @address, 'args' => @args})
    end

    def send!
      # TODO try block?
      send_osc(id,method, *parameters)
      Persistence.mark_as_sent(@id)
    end

    protected
    def new_id
      Time.now.to_i.to_s
    end

    def parse_message_string message_string
      message_array = message_string.split
      [message_array.shift, message_array]
    end

    def send_osc
      OSCConnection.send(@address, @args)
    end
  end
end
