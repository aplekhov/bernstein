module Bernstein
  class OSCConnection
    include OSC

    # TODO make awk mode configurable
    def self.send_message(address, *args)
      connection.send Bundle.new(nil, OSC::Message.new(address,*args), OSC::Message.new('/request_id', id))
    end

    protected
    def connection
      # TODO make this configurable
      @@connection ||= OSC::Client.new 8000
    end
  end
end
