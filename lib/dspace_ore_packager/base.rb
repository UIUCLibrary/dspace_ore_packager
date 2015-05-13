require 'nokogiri'
module DspaceOrePackager
  class Base
    def doPackage(ore_xml)
      dop = Packager.new(ore_xml)
      # dop.processAR
      dop.login
      # dop.getColID
      # dop.createItem
      # dop.processAgg
      # dop.updateMetadata
      dop.postAggBitstream
    end
  end
end