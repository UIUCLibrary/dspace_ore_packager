#!/usr/bin/env ruby

require 'rubygems'
require 'base64'
require 'json'
require 'highline/import'
require 'rest_client'
require 'nokogiri'

# Set the request parameters
host = 'http://localhost:8080'

puts 'Would you like to login?'
ans1 = gets.chomp
if ans1 == 'y' then
  puts 'Enter e-mail address '
  user = gets.chomp
  # Password input without being displayed
  pwd = ask("Enter password: "){|q| q.echo = false}

  begin
    response = RestClient.post("#{host}/rest/login", {"email" => "#{user}", "password" => "#{pwd}"}.to_json,
                               {:content_type => 'application/json',
                                :accept => 'application/json'})
    login_token = response.to_str
    puts "Your login token is: #{login_token}"

  rescue => e
    puts "ERROR: #{e}"
  end
end

#Get the collection ID to POST (create) an item
puts "Would you like to create an item?\nAnswer in y/n"
ans2 = gets.chomp

if ans2 == 'y' then
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

#POST an item
puts "Would you like to create an item under that collection?\nAnswer in y/n"
ans3 = gets.chomp

if ans3 == 'y' then
  puts 'Creating an item.'
  begin
    item = RestClient.post("#{host}/rest/collections/#{collectionid}/items",{"type" => "item"}.to_json,
                           {:content_type => 'application/json', :accept => 'application/json', :rest_dspace_token => "#{login_token}" })
    puts item.to_str
    puts "Response status: #{item.code}"
    getitemid = JSON.parse(item)
    itemid = "#{getitemid["id"]}"
    puts "Item ID is: #{itemid}"
  end
else
  puts 'Redo if you would like to create an item'
end

test_json = '[{"key":"dcterms.modified", "value":"2014-03-24T11:32:03-0400", "language":"en"},{"key":"dcterms.identifier", "value":"http://sead-test/fakeUri/0489a707-d428-4db4-8ce0-1ace548bc653", "language":"en"},{"key":"dcterms.title", "value":"Test update", "language":"en"}]'

begin
  metadata = RestClient.put("#{host}/rest/items/#{itemid}/metadata", "#{test_json}",
                         {:content_type => 'application/json', :accept => 'application/json', :rest_dspace_token => "#{login_token}" })
  puts "Response status: #{metadata.code}"
end
