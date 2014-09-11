module Bernstein
  class Client
    def self.send_message(message)
      msg = Message.build(message)
      msg.save!
      msg.id
    end

    def self.message_status(message_id)
      Persistence.request_status(message_id)
    end
  end
end
