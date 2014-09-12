module Bernstein
  class Client
    ##
    # Example: Bernstein::Client.send_message("/synths/4/filter_cutoff .5")
    #
    def self.send_message(message)
      msg = Message.build(message)
      msg.save!
      msg.id
    end

    ##
    # Example: Bernstein::Client.message_status("34246456458856")
    #
    def self.message_status(message_id)
      Message.get_status(message_id)
    end
  end
end
