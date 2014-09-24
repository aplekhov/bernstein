require 'eventmachine'
require 'ruby-osc'

module Bernstein
  class Server
    @options = {port: 9000, host: '127.0.0.1', listen_for_awks: true, poll_interval: 5, awk_address: '/awk_id'}
    def self.configure!(options = {})
      @options.merge!(options || {})
    end

    def self.start
      OSC.run do
        server = OSC::Server.new(@options[:port],@options[:host])
        if @options[:listen_for_awks] 
          server.add_pattern @options[:awk_address] do |*args|
            handle_awknowledgement(args[1])
          end
        end

        timer = EventMachine::PeriodicTimer.new(@options[:poll_interval]) do 
          begin
            process_queued_messages
          rescue StandardError => e
            # TODO logging
            puts e.backtrace
          end
        end
      end
    end

    private
      def self.process_queued_messages
        Message.get_queued_messages.each{|m| m.send!}
      end

      def self.handle_awknowledgement(id)
        Message.set_as_awknowledged(id)
      end
  end
end
