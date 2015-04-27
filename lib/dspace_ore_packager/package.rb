require 'nokogiri'
require 'rest_client'
require 'json'

module DspaceOrePackager
  class Package
    attr_reader :file, :document, :ars
    def initialize(ore_xml)

      @file = File.new(ore_xml)
      @aggregation_uri='http://www.openarchives.org/ore/terms/Aggregation'
      @document = Nokogiri::XML(@file)
      @agg =  @document.xpath("//rdf:Description[rdf:type/@rdf:resource='#{@aggregation_uri}']")
      @agg_id = @document.xpath("//rdf:Description[rdf:type/@rdf:resource='#{@aggregation_uri}']/@rdf:about")
      @ar_ids= @document.xpath("//rdf:Description[rdf:type/@rdf:resource='#{@aggregation_uri}']/ore:aggregates")
      @ars = @document.xpath("//rdf:Description[ore:isAggregatedBy='#{@agg_id}']")
      @agg_metadata_id = @document.xpath("//rdf:Description[rdf:type/@rdf:resource='#{@aggregation_uri}']/ore:isDescribedBy/@rdf:resource")
      @agg_dcterms = @document.xpath("//rdf:Description[ore:describes/@rdf:resource='#{@agg_id}']/*[starts-with(name(),'dcterms:')]")

      @key = Array.new
      @value = Array.new
      @language = 'en'


    end

    def validate
      #needs to be implemented
    end

    def processAgg

      # puts @agg_dcterms[2]

      # @agg_dcterms.xpath('//h3/a[@class="1"]').each do |dcterms:title|
      #   puts dcterms:title.content

      for term in @agg_dcterms
        if term.to_s() =~ /<.*:(.*?)\s.*">\n\s*<.*>(.*)<.*>\n\s*.*\n\s*<.*>/ then  #extract patterns <dcterms:creator attribute="something"><foaf:name>something</foaf:name></dcterms:creator>, where the element has sub-element
          name =       ($1).to_s
          name_value = ($2).to_s
        elsif term.to_s() =~ /^.*?:(.*?)\s.*>(.*)<.*/ and $1.to_s()!= "" then   #extract patterns like <dcterms:title attribute="something">...</dcterms:title>, where the element has attribute
          name =       ($1).to_s
          name_value = ($2).to_s
        elsif term.to_s() =~  /^.*?:(.*?)>(.*)<.*/ and $1.to_s()!= "" then  #extract patterns like <dcterms:abstract>...</dcterms:abstract>, where there is no attribute of element
          name =       ($1).to_s
          name_value = ($2).to_s
        end
        @key.push(name)
        @value.push(name_value)
      end
      # puts @key
      # puts @value

      @pair = Array.new

      @json = '[';

      len = @key.length - 1
      for i in 0..len
        # if @pair.any? { |hash| hash[':key'].include?(@key[i]) } then
        #   data = 0
        # else
        data = {:key=> @key[i], :value=> @value[i], :language=>"#{@language}"}
        @json += "{\"key\":\"#{@key[i]}\", \"value\":\"#{@value[i]}\", \"language\":\"#{@language}\"}"
        @json += ','
        # end
        # @pair.store(:key,@key[i])
        # @pair.store(:value,@value[i])
        @pair.push(data)
      end

      @json = @json.chop
      @json += "]"

      puts @json



      # Works for single occurrence of an element as index always returns the value of the first object in self
      # @a = @key.map{|e| {:key => e, :language => "en_US", :value => @value[@key.index(e)]}}
      # puts @a.to_json


      @sample = [
          {
          :key=> "dc.coverage.temporal",
          :language=> "en_US",
          :value=> "1911"
      },
          {
              :key=> "dc.creator",
          :language=> "en_US",
          :value=> "Hirsch, Edwin F. (Edwin Frederick), 1886-1972."
      },
          {
              :key=> "dc.date.accessioned",
          :language=> "null",
      :value=> "2014-09-18T16:00:43Z"
      }]
      # puts @sample.to_json


      # @ars.each do |aggResource|
      #   processAR(aggResource)
      # end
    end
    def processAR(ar)
      puts "this doesn't do anything yet"
    end
  end
end

