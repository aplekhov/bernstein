class Test2Handler
  def process_requests(requests, request_manager)
    puts "Test2Handler: processing requests: #{requests.inspect}"
    requests.each do |r|
      request_manager.send_request(r["id"], "/#{r["params"].keys.first}", r["params"].values.first)
    end
  end
end
