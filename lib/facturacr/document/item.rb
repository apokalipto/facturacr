module FE
  class Document
    class Item
      include ActiveModel::Validations

      UNITS = %w[ Al Alc Cm I Os Spe St Sp m kg s A K mol cd m² m³ m/s m/s² 1/m kg/m³ A/m² A/m mol/m³ cd/m² 1 rad sr Hz N Pa J W C V F Ω S Wb T H °C lm
                 lx Bq Gy Sv kat Pa·s N·m N/m rad/s rad/s² W/m² J/K J/(kg·K) J/kg W/(m·K) J/m³ V/m C/m³ C/m² F/m H/m J/mol J/(mol·K)
                 C/kg Gy/s W/sr W/(m²·sr) kat/m³ min h d º ´ ´´ L t Np B eV u ua Unid Gal g Km ln cm mL mm Oz Otros].freeze

      CODE_TYPES = {
        '01' => 'Código del producto del vendedor',
        '02' => 'Código del producto del comprador',
        '03' => 'Código del producto asignado por la industria',
        '04' => 'Código uso interno',
        '99' => 'Otros'
      }.freeze

      attr_accessor :line_number,:tariff_item,:code, :comercial_code_type, :comercial_code, :quantity, :unit, :description, :unit_price, :total,
                    :discount, :discount_reason, :subtotal,:taxable_base ,:taxes,:net_tax ,:net_total, :exoneration

      validates :line_number, presence: true
      validates :tariff_item, presence: true, if:->{:document_type.eql?("01") }
      validates :comercial_code_type, inclusion: CODE_TYPES.keys, if: -> { comercial_code.present? }
      validates :quantity, presence: true, numericality: { greater_than: 0 }
      validates :unit, presence: true, inclusion: UNITS
      validates :description, presence: true, length: { maximum: 200 }
      validates :unit_price, presence: true
      validates :total, presence: true
      validates :discount, numericality: { grater_than: 0 }, if: -> { discount.present? }
      validates :discount_reason, presence: true, if: -> { discount.present? }
      validates :subtotal, presence: true
      validates :taxable_base, presence: true, if: ->{ taxes.map { |t| t.code.eql?("07")  }.include?(true) }
      validates :net_tax,presence:true, if: ->{exoneration.present?}
      validates :net_total, presence: true
      validates :comercial_code, presence: true, length: {maximum: 20}
      validates :code, length: {maximum: 13}


      def initialize(args = {})
        @line_number = args[:line_number]
        @code = args[:code]
        @comercial_code_type = args[:comercial_code_type].presence || '01'
        @comercial_code = args[:comercial_code]
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
        @exoneration = args[:exoneration]
        @net_tax = args[:net_tax]
        @tariff_item = args[:tariff_item]
      end

      def build_xml(node)
        raise "Item invalid: #{errors.messages}" unless valid?

        node = Nokogiri::XML::Builder.new if node.nil?
        node.LineaDetalle do |x|
          x.NumeroLinea @line_number

          x.PartidaArancelaria @tariff_item if @tariff_item.present? && FE.configuration.version_43?

          x.Codigo @code if @code.present? && FE.configuration.version_43?

          if @comercial_code.present? && FE.configuration.version_43?
            x.CodigoComercial do |x2|
              x2.TipoCodigo @comercial_code_type
              x2.CodigoComercial @comercial_code
            end
          end

          if @comercial_code.present? && FE.configuration.version_42?
            x.Codigo do |x2|
              x2.Tipo @comercial_code_type
              x2.Codigo @comercial_code
            end
          end
          x.Cantidad @quantity
          x.UnidadMedida @unit
          x.Detalle @description
          x.PrecioUnitario @unit_price
          x.MontoTotal @total

          if @discount.present?
            x.Descuento do |x2|
              x2.TipoDescuento @discount_reason
              x2.Descuento @discount
          end

          end

          x.SubTotal @subtotal

          x.BaseImponible @taxable_base if @taxable_base.present? && FE.configuration.version_43?
          @taxes.each do |tax|

            tax.build_xml(x)
          end

          x.ImpuestoNeto @net_tax if @net_tax.present? && @exoneration.present?
          x.MontoTotalLinea @net_total
        end

      end

      
    end
  end
end
