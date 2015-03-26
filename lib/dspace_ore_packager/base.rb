require 'nokogiri'
module DspaceOrePackager
  class Base
    def doPackage(ore_xml)
      dop = DspaceOrePackager.new(ore_xml)
    end
  end
end