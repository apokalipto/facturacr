require 'facturacr/document'

module FE
  class Document
    class Reference
      include ActiveModel::Validations

      attr_accessor :document_type, :number, :date, :code, :reason

      REFERENCE_CODES = {
        "01" => "Anula Documento de referencia",
        "02" => "Corrige texto documento de referencia",
        "03" => "Corrige monto",
        "04" => "Referencia a otro documento",
        "05" => "Sustituye comprobante provisional por contingencia",
        "99" => "Otros"
      }.freeze

      validates :document_type, presence: true, inclusion: FE::Document::DOCUMENT_TYPES.keys
      #validates :number, presence: true, length: {maximum: 50}, if: ->{ document_type.present? }
      validates :date, presence: true
      #validates :code, presence: true, length: {is: 2}, inclusion: REFERENCE_CODES.keys, if: ->{ document_type.present? }
      validates :reason, presence: true, length: {maximum: 180}, if: ->{ document_type.present? }

      def initialize(args={})
        @document_type = args[:document_type]
        @number = args[:number]
        @date = args[:date]
        @code = args[:code]
        @reason = args[:reason]
      end

      def build_xml(node)
        raise "Reference Invalid: #{errors.messages}" unless valid?
        node = Nokogiri::XML::Builder.new if node.nil?
        node.InformacionReferencia do |xml|
          xml.TipoDoc @document_type
          xml.Numero @number
          xml.FechaEmision @date.xmlschema
          xml.Codigo @code
          xml.Razon @reason
        end
      end
    end
  end
end
