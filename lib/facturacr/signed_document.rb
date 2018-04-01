require 'base64'

module FE
  class SignedDocument
    attr_accessor :document, :path, :base64, :payload
    
    def initialize(document, path)
      @document = document
      @path = path
      @base64 = nil
      if File.exist?(@path)
        file = File.open(@path,"rb")
        @base64 = Base64.encode64(file.read).gsub("\n","");
      end
      @payload = document.api_payload
      @payload[:comprobanteXml] = @base64
    end
  end
end