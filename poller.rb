require 'rubygems'
require 'isis'

include Isis

loop do
  puts "checking for new queued requests"
  process_queued_requests
  sleep 5
end
