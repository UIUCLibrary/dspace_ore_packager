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
      @ars_dcterms = @document.xpath("//rdf:Description[ore:isAggregatedBy='#{@agg_id}']/*[starts-with(name(),'dcterms:')]")
      # @agg_metadata_id = @document.xpath("//rdf:Description[rdf:type/@rdf:resource='#{@aggregation_uri}']/ore:isDescribedBy/@rdf:resource")

    end

    def validate
      #needs to be implemented
    end

    def processAgg

      #Login
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

      # Retrieve collection id to create an item
      handle_id = ask("Enter handle ID of the collection: ")
      begin
        collection = RestClient.get("#{host}/rest/handle/2142/#{handle_id}")
        doc = Nokogiri::XML(collection)
        getid = doc.xpath("//collection/id")
        collectionid = "#{getid}"[/.*>(.*)</,1]
        puts "collection id is: #{collectionid}"
      end

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

      # Extract
      key = Array.new
      value = Array.new
      language = 'en'
      for term in @agg_dcterms
        # extract patterns <dcterms:creator attribute="something"><foaf:name>something</foaf:name></dcterms:creator>, where the element has sub-element
        if term.to_s() =~ /<(.*?)\s.*">\n\s*<.*>(.*)<.*>\n\s*.*\n\s*<.*>/ then
          name =       ($1).to_s
          name_value = ($2).to_s

          # extract patterns like <dcterms:title attribute="something">...</dcterms:title>, where the element has attribute
        elsif term.to_s() =~ /^<(.*?)\s.*>(.*)<.*/ and $1.to_s()!= "" then
          name =       ($1).to_s
          name_value = ($2).to_s

          # extract patterns like <dcterms:abstract>...</dcterms:abstract>, where there is no attribute of element
        elsif term.to_s() =~  /^<(.*?)>(.*)<.*/ and $1.to_s()!= "" then
          name =       ($1).to_s
          name_value = ($2).to_s
        end
        key.push(name)
        value.push(name_value)
      end
      # puts @key
      # puts @value


      terms = "["
      len = key.length - 1
      for i in 0..len
        key[i].sub!(':','.')
        terms += "{\"key\":\"#{key[i]}\", \"value\":\"#{value[i]}\", \"language\":\"#{language}\"}"
        terms += ','
      end

      terms = terms.chop
      terms += "]"

      puts terms.to_s

      #Update metadata
      puts 'Updating item metadata'
      begin
        metadata = RestClient.put("#{host}/rest/items/#{itemid}/metadata", "#{terms}",
                                  {:content_type => 'application/json', :accept => 'application/json', :rest_dspace_token => "#{login_token}" })
        puts "Response status: #{metadata.code}"
      end
    end


    # Aggregated resources
    def processAR
      ids = @document.xpath("//rdf:Description/@rdf:about")
      md = Array.new
      len = @ar_ids.length - 1
      for i in 0..len
        if @ar_ids[i].include?@document.xpath("//rdf:Description/@rdf:about") then
          md[i] = @document.xpath("//rdf:Description[ore:isAggregatedBy='#{@agg_id}']/*[starts-with(name(),'dcterms:')]")
        end
      end

      test = (ids & @ar_ids).empty?
      puts test
    end
  end
end

