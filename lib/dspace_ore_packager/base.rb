require 'nokogiri'
module DspaceOrePackager
  class Base
    def doPackage(ore_xml)
      dop = Packager.new(ore_xml)
      # dop.processAgg
      dop.processAR
    end
  end
end