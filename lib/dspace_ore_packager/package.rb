require 'nokogiri'
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
      @agg_metadata = @document.xpath("//rdf:Description[@about = '#{@add_metadata_id}']")
    end

    def validate
      #needs to be implemented
    end

    def processAgg
      puts @ars
      @ars.each do |aggResource|
        processAR(aggResource)
      end
    end
    def processAR(ar)
      puts "this doesn't do anything yet"
    end
  end
end

