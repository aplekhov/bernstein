module Bernstein
  class Server
    def self.process_queued_messages
      Persistence.queued_messages.each{|m| m.send!}
    end

    def self.handle_request_awknowledgement(id)
      Persistence.mark_as_awknowledged(id)
    end

    def self.start
      OSC.run do
        # TODO configure
        server = Server.new(port,host)
        server.add_pattern "/awk_id" do |*args|
          puts "received awk for request #{args[1]}"
          handle_request_awknowledgement(args[1])
        end

        timer = EventMachine::PeriodicTimer.new(5) do 
          puts "checking for new queued requests"
          begin
            process_queued_requests
          rescue StandardError => e
            puts e.backtrace
          end
        end
      end
    end
  end
end
