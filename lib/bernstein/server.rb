require 'eventmachine'
require 'ruby-osc'

module Bernstein
  class Server
    @options = {port: 9000, host: '127.0.0.1', require_awks: true, poll_interval: 5, awk_address: '/awk_id'}
    def self.configure!(options = {})
      @options.merge!(options || {})
    end

    def self.start
      OSC.run do
        @server = OSC::Server.new(@options[:port],@options[:host])
        if @options[:require_awks] 
          @server.add_pattern @options[:awk_address] do |*args|
            handle_awknowledgement(args[1])
          end
        end

        @timer = EventMachine::PeriodicTimer.new(@options[:poll_interval]) do 
          process_queued_messages
        end
        yield if block_given?
      end
    end

    def self.stop
      @server.stop unless @server.nil?
      @timer.cancel unless @timer.nil?
    end

    private
      def self.process_queued_messages
        Message.get_queued_messages.each{|m| m.send!(@options[:require_awks])}
      end

      def self.handle_awknowledgement(id)
        Message.set_as_sent!(id)
      end
  end
end
