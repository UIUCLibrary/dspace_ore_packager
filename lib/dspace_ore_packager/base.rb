require 'nokogiri'
module DspaceOrePackager
  class Base
    def doPackage(ore_xml)
      dop = Package.new(ore_xml)
      dop.processAgg


    end
  end
end