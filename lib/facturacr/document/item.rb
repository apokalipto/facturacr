module FE
  class Document
    class Item
      include ActiveModel::Validations

      UNITS = %w[Sp m kg s A K mol cd m² m³ m/s m/s² 1/m kg/m³ A/m² A/m mol/m³ cd/m² 1 rad sr Hz N Pa J W C V F Ω S Wb T H °C lm
                 lx Bq Gy Sv kat Pa·s N·m N/m rad/s rad/s² W/m² J/K J/(kg·K) J/kg W/(m·K) J/m³ V/m C/m³ C/m² F/m H/m J/mol J/(mol·K)
                 C/kg Gy/s W/sr W/(m²·sr) kat/m³ min h d º ´ ´´ L t Np B eV u ua Unid Gal g Km ln cm mL mm Oz Otros].freeze

      CODE_TYPES = {
        '01' => 'Código del producto del vendedor',
        '02' => 'Código del producto del comprador',
        '03' => 'Código del producto asignado por la industria',
        '04' => 'Código uso interno',
        '99' => 'Otros'
      }.freeze

      attr_accessor :line_number, :code_type, :code, :quantity, :unit, :description, :unit_price, :total,
                    :discount, :discount_reason, :subtotal, :taxes, :net_total

      validates :line_number, presence: true
      validates :code_type, inclusion: CODE_TYPES.keys, if: -> { code.present? }
      validates :quantity, presence: true, numericality: { greater_than: 0 }
      validates :unit, presence: true, inclusion: UNITS
      validates :description, presence: true, length: { maximum: 160 }
      validates :unit_price, presence: true
      validates :total, presence: true
      validates :discount, numericality: { grater_than: 0 }, if: -> { discount.present? }
      validates :discount_reason, presence: true, if: -> { discount.present? }
      validates :subtotal, presence: true
      validates :net_total, presence: true
      validates :code, presence: true, length: {maximum: 20}

      def initialize(args = {})
        @line_number = args[:line_number]
        @code_type = args[:code_type].presence || '01'
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
              x2.Tipo @code_type
              x2.Codigo @code
            end
          end
          x.Cantidad @quantity
          x.UnidadMedida @unit
          x.Detalle @description
          x.PrecioUnitario @unit_price
          x.MontoTotal @total
          x.MontoDescuento @discount if @discount.present?
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
