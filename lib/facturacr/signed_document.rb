require 'base64'

module FE
  class SignedDocument
    attr_accessor :document, :base64, :payload
    
    def initialize(document, xml_provider)
      # Backwards compatibility with v0.1.4
      if xml_provider.is_a?(String)
        raise ArgumentError, "File: #{xml_provider} does not exist" unless File.exists?(xml_provider)
        xml_provider = FE::DataProvider.new(:file, xml_provider)
      end
      raise ArgumentError, "Invalid Argument" unless xml_provider.is_a?(FE::DataProvider)
      
      @document = document
      @base64 = Base64.encode64(xml_provider.contents).gsub("\n","");
      @payload = document.api_payload
      @payload[:comprobanteXml] = @base64
    end
  end
end