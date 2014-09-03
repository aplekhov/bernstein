require 'isis'

include Isis

loop do
  puts "press r for new request or c to check request status"
  choice = gets.chomp
  if choice == 'r'
    puts "enter value to send:"
    value = gets.chomp.to_f
    r_id = save_new_request('TestHandler', {'value' => value})
    puts "saved new request with id #{r_id}"
  elsif choice == 'c'
    puts "enter request id"
    r_id = gets.chomp
    status = request_status(r_id)
    puts "status is #{status}"
  else
    puts "bad choice"
  end
end
