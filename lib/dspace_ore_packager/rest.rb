#!/usr/bin/env ruby

require 'rubygems'
require 'base64'
require 'json'
require 'highline/import'
require 'rest_client'
require 'nokogiri'

# Set the request parameters
host = 'http://localhost:8080'
puts 'Enter e-mail address '
user = gets.chomp
# Password input without being displayed
pwd = ask("Enter password: "){|q| q.echo = false}

begin
  response = RestClient.post("#{host}/rest/login", {"email" => "#{user}", "password" => "#{pwd}"}.to_json,
                              {:content_type => 'application/json',
                              :accept => 'application/json'})
  login_token = response.to_str
  puts login_token

rescue => e
  puts "ERROR: #{e}"
end

#Get the collection ID to POST (create) an item
puts "Would you like to create an item?\nAnswer in y/n"
ans1 = gets.chomp

if ans1 == 'y' then
  puts 'Enter the handle ID of the collection'
  handle_id = gets.chomp
  begin
  collection = RestClient.get("#{host}/rest/handle/2142/#{handle_id}")
  doc = Nokogiri::XML(collection)
  getid = doc.xpath("//collection/id")
  collectionid = "#{getid}"[/.*>(.*)</,1]
    puts "collection id is: #{collectionid}"
  end
  else puts 'Cannot get collection ID'
end

puts "Would you like to create an item under that collection?\nAnswer in y/n"
ans2 = gets.chomp

if ans2 == 'y' then
  puts 'Creating an item.'
  begin
    item = RestClient.post("#{host}/rest/collections/#{collectionid}/items",{"type" => "item"}.to_json,
                           {:content_type => 'application/json', :accept => 'application/json', :rest_dspace_token => "#{login_token}" })
    puts item.to_str
    puts "Response status: #{item.code}"
    getitemid = JSON.parse(item)
    puts "Item ID is: #{getitemid["id"]}"
  end
else
  puts 'Redo if you would like to create an item'
end

# POST format for DSpace
# curl -X POST -H "Content-Type: application/json" -H "rest-dspace-token: a8929bbf-6430-4552-8e28-17acfcc9e7a5" -d '{"name":"test2", "type":"item"}' http://localhost:8080/rest/collections/530/items
#curl -X PUT -H "Content-Type: application/json" -H "rest-dspace-token:a8929bbf-6430-4552-8e28-17acfcc9e7a5" -d '[{"key":"dc.title", "value":"Test Item", "language":"en"}, {"key": "dc.creator", "value":"Nushrat", "language":"en"}]' http://localhost:8080/rest/items/55390/metadata
