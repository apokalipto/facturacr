module FE
  class Document
    class PaymentMethod < Element
      include ActiveModel::Validations
      attr_accessor :payment_type, :payment_type_other, :amount

      validates :payment_type, presence: true, inclusion: FE::Document::PAYMENT_TYPES.keys
      validates :payment_type_other, presence: true,length: {minimum: 3, maximum: 100}, if: -> {payment_type.eql?("99")}

      def initialize(args={})
        @payment_type = args[:payment_type] || "01"
        @payment_type_other = args[:payment_type_other]
        @amount = args[:amount]
      end

      def build_xml(node, document)
        raise FE::Error.new("payment_method is not a hash",class: self.class) unless valid?

        node = Nokogiri::XML::Builder.new if node.nil?

        node.MedioPago do |xml|
          xml.TipoMedioPago @payment_type
          xml.MedioPagoOtros @payment_type_other if @payment_type_other
          xml.TotalMedioPago @amount
        end
      end
    end
  end
end
