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
      @ar_titles = @document.xpath("//rdf:Description[ore:isAggregatedBy='#{@agg_id}']/*[starts-with(name(),'dcterms:title')]")
      # @ar_metadata = @document.xpath("//rdf:Description[@rdf:about='#{@ar_ids[0]}']/*[starts-with(name(),'dcterms:')]")

      @host = 'http://localhost:8080'
      @language = 'en'
    end

    def validate
      #needs to be implemented
    end

    def login
      user = 'njkhan505@gmail.com'
      pwd = '123456'
      begin
        response = RestClient.post("#{@host}/rest/login", {"email" => "#{user}", "password" => "#{pwd}"}.to_json,
                                   {:content_type => 'application/json',
                                    :accept => 'application/json'})
        @login_token = response.to_str
        puts "Your login token is: #{@login_token}"

      rescue => e
        puts "ERROR: #{e}"
      end
    end


    def getColID

      # Retrieve collection id to create an item
      handle_id = ask("Enter handle ID of the collection: ")
      begin
        collection = RestClient.get("#{@host}/rest/handle/2142/#{handle_id}")
        doc = Nokogiri::XML(collection)
        getid = doc.xpath("//collection/id")
        @collectionid = "#{getid}"[/.*>(.*)</,1]
        puts "collection id is: #{@collectionid}"
      end
    end


    def createItem

      #Create an item
      puts 'Creating an item.'
      begin
        item = RestClient.post("#{@host}/rest/collections/#{@collectionid}/items",{"type" => "item"}.to_json,
                               {:content_type => 'application/json', :accept => 'application/json', :rest_dspace_token => "#{@login_token}" })
        puts item.to_str
        puts "Response status: #{item.code}"
        getitemid = JSON.parse(item)
        @itemid = "#{getitemid["id"]}"
        puts "Item ID is: #{@itemid}"
      end
    end


    def updateMetadata

      #Update metadata
      puts 'Updating item metadata'
      begin
        metadata = RestClient.put("#{@host}/rest/items/#{@itemid}/metadata", "#{@content.to_json}",
                                  {:content_type => 'application/json', :accept => 'application/json', :rest_dspace_token => "#{@login_token}" })
        puts "Response status: #{metadata.code}"
      end

    end


    def postAggBitstream
      folder = '/Users/njkhan2/Projects/dspace_ore_packager/test/d6d250ba-e54d-4ae0-937d-c23d5e8b5de8'
      ore_filepath= Dir.glob("#{folder}/*_oaiore.xml")
      puts ore_filepath[0]

      file_name = File.basename("#{ore_filepath[0]}")
      puts "#{file_name}"

      begin
        bitstream = RestClient.post("#{@host}/rest/items/#{@itemid}/bitstreams?name=#{file_name}",
                                    {
                                        :transfer =>{
                                            :type => 'bitstream'
                                        },
                                        :upload => {
                                        :file => File.new("#{ore_filepath[0]}",'rb')
                                    }
                                     } ,{:content_type => 'application/json', :accept => 'application/json', :rest_dspace_token => "#{@login_token}" })
        puts "Response status: #{bitstream.code}"
      end

    end


    def processAgg

      # Extract aggregator metadata
      @content = @agg_dcterms.map{|node|
        name = node.xpath("name()").sub!(':','.')
        value = node.name == "contributor"||node.name =="creator" ? node.xpath("foaf:name/text()") : node.xpath("text()")
        {'key'=>"#{name}", 'value'=>"#{value}", 'language'=>"#{@language}"}
      }
      puts @content.to_json

    end


    # Get metadata of the aggregated resources
    def processAR

      # puts @ar_metadata
      collect_all = []
      values = []
      for i in 0..(@ar_ids.length-1)
        ar_metadata = @document.xpath("//rdf:Description[@rdf:about='#{@ar_ids[i]}']/*[starts-with(name(),'dcterms:')]")
        get_armetadata = ar_metadata.map{|node|
          name = node.xpath("name()").sub!(':','.')
          value = node.name == "contributor"||node.name =="creator" ? node.xpath("foaf:name/text()") : node.xpath("text()")
          {'key'=>"#{name}", 'value'=>"#{value}", 'language'=>"#{@language}"}

          # values << "#{value}"
        }
        collect_all << get_armetadata
        # if (filenames & values) then
        #   puts filenames
        #   begin
        #     metadata = RestClient.put("#{@host}/rest/items/#{@itemid}/metadata", "#{get_armetadata.to_json}",
        #                               {:content_type => 'application/json', :accept => 'application/json', :rest_dspace_token => "#{@login_token}" })
        #     puts "Response status: #{metadata.code}"
        #   end
        # end
        # break
      end

      puts collect_all.to_json
    end


    def post_arbitstreams

      login
      getColID

      folder = '/Users/njkhan2/Projects/dspace_ore_packager/test/d6d250ba-e54d-4ae0-937d-c23d5e8b5de8'
      filepaths= Dir.glob("#{folder}/*/*")

      filenames = []
      filepaths.each do|fname|
        files = File.basename(fname)
        filenames << files
      end


      # titles = @ar_titles.collect { |dcterms| dcterms.child.to_s }

      for i in 0..(filepaths.length-1)

          createItem

          # postBitstream
          begin
            bitstream = RestClient.post("#{@host}/rest/items/#{@itemid}/bitstreams?name=#{filenames[i].gsub(/\s/,'_')}",
                                        {
                                            :transfer =>{
                                                :type => 'bitstream'
                                            },
                                            :upload => {
                                                :file => File.new("#{filepaths[i]}",'rb')
                                            }
                                        } ,{:content_type => 'application/json', :accept => 'application/json', :rest_dspace_token => "#{@login_token}" })
            puts "Response status: #{bitstream.code}"
          end

      end

    end

  end
end

