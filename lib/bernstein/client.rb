module Bernstein
  class Client
    ##
    # Example: Bernstein::Client.send_message("/synths/4/filter_cutoff .5")
    # note: only accepts float arguments
    #
    def self.send_message_by_string(message_string)
      msg = Message.build_from_string(message_string)
      save_and_return_id(msg)
    end

    ##
    # Example: Bernstein::Client.send_message("/synths/frequencies", 440, 556.3 334.0")
    # note: only accepts float arguments
    #
    def self.send_message(address = '/', *args)
      msg = Message.build(address, *args)
      save_and_return_id(msg)
    end

    ##
    # Example: Bernstein::Client.message_status("34246456458856")
    #
    def self.message_status(message_id)
      Message.get_status(message_id)
    end

    private
    def self.save_and_return_id(msg)
      msg.save!
      msg.id
    end
  end
end
