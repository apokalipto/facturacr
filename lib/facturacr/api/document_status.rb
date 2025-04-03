require 'base64'
require 'json'
require 'nokogiri'

module FE
  class Api
    class DocumentStatus

      attr_reader :document
      attr_accessor  :json, :xml, :key, :date, :status

      def initialize(json)
        @json = json
        @response = JSON.parse(json)
        @xml = Base64.decode64(@response["respuesta-xml"]) if @response["respuesta-xml"]
        @status = @response["ind-estado"]
        @date = @response["fecha"]
        @key = @response["clave"]
        @document = Nokogiri::XML(@xml) if @xml
      end

      def details
        @document.css("MensajeHacienda DetalleMensaje").first.try(:text) if @document
      end

      def to_h
        {
          key: @key,
          date:  @date,
          status: @status,
          details: details
        }
      end
    end
  end
end
