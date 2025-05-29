module FE
  class Document
    class TaxSummary < Element
      include ActiveModel::Validations

      attr_accessor :code, :rate_code, :total

      validates :rate_code, inclusion: Tax::RATE_CODES.keys, presence: true, if:->{ rate_code.present?}
      validates :code, presence: true, inclusion: Tax::TAX_CODES.keys


      def initialize(args={})
        @code = args[:code]
        @rate_code = args[:rate_code]
        @total = args[:total]
      end


      def build_xml(node, document)
        @document = document
        raise FE::Error.new("tax invalid",class: self.class, messages: errors.messages) unless valid?
        node = Nokogiri::XML::Builder.new if node.nil?

        node.TotalDesgloseImpuesto do |xml|
          xml.Codigo @code
          xml.CodigoTarifaIVA @rate_code if @rate_code.present?
          xml.TotalMontoImpuesto @total
        end
      end
    end
  end
end
