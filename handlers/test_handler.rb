class TestHandler
  def process_requests(requests, request_manager)
    puts "TestHandler: processing requests: #{requests.inspect}"
    if requests.size == 1
      request_manager.send_request(requests.first["id"], "/transpose", requests.first["params"]["value"].to_f)
    else
      values = requests.map{|r| r["params"]['value']}
      new_value = values.inject{|c,m| c.to_f + m.to_f} / values.size.to_f
      request_manager.merge_requests(requests.map{|r| r['id']}, "/test", new_value)
    end
  end
end
