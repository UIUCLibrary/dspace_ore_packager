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

test_json = '[{"key":"dcterms.modified", "value":"2014-03-24T11:32:03-0400", "language":"en"},{"key":"dcterms.identifier", "value":"http://sead-test/fakeUri/0489a707-d428-4db4-8ce0-1ace548bc653", "language":"en"},{"key":"dcterms.title", "value":"Vortex2 Visualization", "language":"en"},{"key":"dcterms.abstract", "value":"The Vortex2 project (http://www.vortex2.org/home/) supported 100 scientists using over 40 science support vehicles participated in a nomadic effort to understand tornados. For the six weeks from May 1st to June 15th, 2010, scientists went roaming from state-to-state following severe weather conditions. With the help of meteorologists in the field who initiated boundary conditions, LEAD II (https://portal.leadproject.org/gridsphere/gridsphere) delivered six forecasts per day, starting at 7am CDT, creating up to 600 weather images per day. This information was used by the VORTEX2 field team and the command and control center at the University of Oklahoma to determine when and where tornadoes are most likely to occur and to help the storm chasers get to the right place at the right time. VORTEX2 used an unprecedented fleet of cutting edge instruments to literally surround tornadoes and the supercell thunderstorms that form them. An armada of mobile radars, including the Doppler On Wheels (DOW) from the Center for Severe Weather Research (CSWR), SMART-Radars from the University of Oklahoma, the NOXP radar from the National Severe Storms Laboratory (NSSL), radars from the University of Massachusetts, the Office of Naval Research and Texas Tech University (TTU), 12 mobile mesonet instrumented vehicles from NSSL and CSWR, 38 deployable instruments including Sticknets (TTU), Tornado-Pods (CSWR), 4 disdrometers (University of Colorado (CU)), weather balloon launching vans (NSSL, NCAR and SUNY-Oswego), unmanned aircraft (CU), damage survey teams (CSWR, Lyndon State College, NCAR), and photogrammetry teams (Lyndon State Univesity, CSWR and NCAR), and other instruments.", "language":"en"},{"key":"dcterms.publisher", "value":"http://d2i.indiana.edu/", "language":"en"},{"key":"dcterms.rights", "value":"All the data and visualizations are available for download and re-use. Proper attribution to the authors is required.", "language":"en"},{"key":"dcterms.creator", "value":"Quan Zhou", "language":"en"}]'

begin
  metadata = RestClient.put("#{host}/rest/items/55398/metadata", "#{test_json}",
                         {:content_type => 'application/json', :accept => 'application/json', :rest_dspace_token => "#{login_token}" })
  puts "Response status: #{metadata.code}"
end
