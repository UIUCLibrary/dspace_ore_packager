require 'nokogiri'
module DspaceOrePackager
  class Base
    def doPackage(ore_xml)
      dop = Packager.new(ore_xml)

      # dop.login
      # dop.getColID
      # dop.createItem
      # dop.processAgg
      # dop.updateMetadata
      # dop.postAggBitstream


      # dop.processAR
      dop.post_arbitstreams
    end
  end
end