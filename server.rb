require 'rubygems'
require 'ruby-osc'
require 'isis'
require 'eventmachine'

include OSC
include Isis

port = 8080
host = "127.0.0.1"

puts "starting server..."
puts "Enter port (default: 8080)"
gets.chomp.tap{|p| port = p.to_i unless p.empty?}

puts "Enter host (default: 127.0.0.1)"
gets.chomp.tap{|h| host = h unless h.empty?}


OSC.run do
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
