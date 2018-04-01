module FE
  class Document
    class Item
      include ActiveModel::Validations
      
      attr_accessor :line_number, :code, :quantity, :unit, :description, :unit_price, :total,
                    :discount, :discount_reason, :subtotal, :taxes, :exoneration, :net_total
                    
      validates :line_number, presence: true
      validates :quantity, presence: true, numericality: {greater_than: 0}
      validates :unit, presence: true
      validates :description, presence: true, length: {maximum: 160 }
      validates :unit_price, presence: true
      validates :total, presence: true
      validates :discount, numericality: { grater_than: 0}, if: ->{ discount.present? }
      validates :discount_reason, presence: true, if: ->{ discount.present? }
      validates :subtotal, presence: true
      validates :net_total, presence: true
      
      
      def initialize(args={})
        @line_number = args[:line_number]
        @code = args[:code]
        @quantity = args[:quantity]
        @unit = args[:unit]
        @description = args[:description]
        @unit_price = args[:unit_price]
        @total = args[:total]
        @discount = args[:discount]
        @discount_reason = args[:discount_reason]
        @subtotal = args[:subtotal]
        @taxes = args[:taxes] || []
        @net_total = args[:net_total]
      end
      
      def build_xml(node)
        raise "Item invalid: #{errors.messages}" unless valid?
        node = Nokogiri::XML::Builder.new if node.nil?
        node.LineaDetalle do |x|
          x.NumeroLinea @line_number
          if @code.present?
            x.Codigo do |x2|
              x2.Tipo "01"
              x2.Codigo @code
            end
          end
          x.Cantidad @quantity
          x.UnidadMedida @unit
          x.Detalle @description
          x.PrecioUnitario @unit_price
          x.MontoTotal @total
          x.Discount @discount if @discount.present?
          x.NaturalezaDescuento @discount_reason if @discount_reason.present?
          x.SubTotal @subtotal
          @taxes.each do |tax|
            tax.build_xml(x)
          end
          if @exoneration.present?
            @exoneration.build_xml(x)
          end
          x.MontoTotalLinea @net_total
        end
      end
      
    end
  end
end