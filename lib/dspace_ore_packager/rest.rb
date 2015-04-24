#!/usr/bin/env ruby

require 'base64'
require 'json'

#   gem install rest-client
require 'rest_client'

# Set the request parameters
host = 'http://localhost:8080'
user = 'njkhan505@gmail.com'
pwd = '123456'

begin
  response = RestClient.post("#{host}/rest/login", {"email" => "#{user}", "password" => "#{pwd}"}.to_json,
                              {:content_type => 'application/json',
                              :accept => 'application/json'})
  login_token = response.to_str
  puts login_token

rescue => e
  puts "ERROR: #{e}"
end

# POST format for DSpace
#curl -X PUT -H "Content-Type: application/json" -H "rest-dspace-token:a8929bbf-6430-4552-8e28-17acfcc9e7a5" -d '[{"key":"dc.title", "value":"Test Item", "language":"en"}, {"key": "dc.creator", "value":"Nushrat", "language":"en"}]' http://localhost:8080/rest/items/55390/metadata
# test item posted - handle 2142/55278