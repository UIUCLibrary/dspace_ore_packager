require 'rubygems'
require 'nokogiri'
require 'rest_client'
require 'json'
require 'highline/import'

module DspaceOrePackager
  class Packager
    attr_reader :file, :document, :ars
    def initialize(ore_xml)

      @file = File.new(ore_xml)
      @aggregation_uri='http://www.openarchives.org/ore/terms/Aggregation'
      @document = Nokogiri::XML(@file)
      @agg_id = @document.xpath("//rdf:Description[rdf:type/@rdf:resource='#{@aggregation_uri}']/@rdf:about")
      @agg_dcterms = @document.xpath("//rdf:Description[ore:describes/@rdf:resource='#{@agg_id}']/*[starts-with(name(),'dcterms:')]")
      # @agg =  @document.xpath("//rdf:Description[rdf:type/@rdf:resource='#{@aggregation_uri}']")
      @ar_ids= @document.xpath("//rdf:Description[rdf:type/@rdf:resource='#{@aggregation_uri}']/ore:aggregates/@rdf:resource")
      # @ars = @document.xpath("//rdf:Description[ore:isAggregatedBy='#{@agg_id}']")
      # @ars_dcterms = @document.xpath("//rdf:Description[ore:isAggregatedBy='#{@agg_id}']/*[starts-with(name(),'dcterms:')]")
      # @ar_metadata = @document.xpath("//rdf:Description[@rdf:about='#{@ar_ids[0]}']/*[starts-with(name(),'dcterms:')]")

    end

    def validate
      #needs to be implemented
    end

    def login
      host = 'http://localhost:8080'
      user = 'njkhan505@gmail.com'
      pwd = '123456'
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


    def getColID

      # Retrieve collection id to create an item
      handle_id = ask("Enter handle ID of the collection: ")
      begin
        collection = RestClient.get("#{host}/rest/handle/2142/#{handle_id}")
        doc = Nokogiri::XML(collection)
        getid = doc.xpath("//collection/id")
        collectionid = "#{getid}"[/.*>(.*)</,1]
        puts "collection id is: #{collectionid}"
      end
    end


    def createItem

      #Create an item
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
    end


    def processAgg

      # Extract aggregator metadata
      key = Array.new
      value = Array.new
      language = 'en'

      @agg_dcterms.each do |node|
        key_name = node.xpath("name()").sub!(':','.')
        key_value = node.name == "creator" ? node.xpath("foaf:name/text()") : node.xpath("text()")
        key << key_name
        value << key_value
      end

      terms = "["
      len = key.length - 1
      for i in 0..len
        terms += "{\"key\":\"#{key[i]}\", \"value\":\"#{value[i]}\", \"language\":\"#{language}\"}"
        terms += ','
      end

      terms = terms.chop
      terms += "]"

      puts terms.to_s
    end


    def updateMetadata

      #Update metadata
      puts 'Updating item metadata'
      begin
        metadata = RestClient.put("#{host}/rest/items/#{itemid}/metadata", "#{terms}",
                                  {:content_type => 'application/json', :accept => 'application/json', :rest_dspace_token => "#{login_token}" })
        puts "Response status: #{metadata.code}"
      end

      folder = '/Users/njkhan2/Projects/dspace_ore_packager/test/d6d250ba-e54d-4ae0-937d-c23d5e8b5de8/'
      ore_filepath= Dir.glob("#{folder}/*_oaiore.xml")
      puts ore_filepath

    end


    # Aggregated resources
    def processAR

      for i in 0..(@ar_ids.length-1)
        @document.xpath("//rdf:Description[@rdf:about='#{@ar_ids[i]}']/*[starts-with(name(),'dcterms:')]").each do |node|
          name = node.xpath("name()")
          value = node.name == "contributor" ? node.xpath("foaf:name/text()") : node.xpath("text()")
          puts "#{name} = #{value}"
        end
      end


      # folder = '/Users/njkhan2/Projects/dspace_ore_packager/test/d6d250ba-e54d-4ae0-937d-c23d5e8b5de8'
      # filepath= Dir.glob("#{folder}/*/*")
      # puts filepath

    end
  end
end

