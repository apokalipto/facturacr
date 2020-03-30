module FE
  class Document
    class Item < Element
      include ActiveModel::Validations

      UNITS = %w[ Al Alc Cm I Os Spe St Sp m kg s A K mol cd m² m³ m/s m/s² 1/m kg/m³ A/m² A/m mol/m³ cd/m² 1 rad sr Hz N Pa J W C V F Ω S Wb T H °C lm
                 lx Bq Gy Sv kat Pa·s N·m N/m rad/s rad/s² W/m² J/K J/(kg·K) J/kg W/(m·K) J/m³ V/m C/m³ C/m² F/m H/m J/mol J/(mol·K)
                 C/kg Gy/s W/sr W/(m²·sr) kat/m³ min h d º ´ ´´ L t Np B eV u ua Unid Gal g Km ln cm mL mm Oz Otros].freeze
      SERVICE_UNITS = %w[Al Alc Os Spe Sp St Cm]
      CODE_TYPES = {
        '01' => 'Código del producto del vendedor',
        '02' => 'Código del producto del comprador',
        '03' => 'Código del producto asignado por la industria',
        '04' => 'Código uso interno',
        '99' => 'Otros'
      }.freeze

      attr_accessor :line_number,:tariff_item,:code, :comercial_code_type, :comercial_code, :quantity, :unit, :description, :unit_price, :total,
                    :discount, :discount_reason, :subtotal,:taxable_base ,:taxes,:net_tax ,:net_total, :exoneration, :document_type

      validates :document_type, presence: true, inclusion: FE::Document::DOCUMENT_TYPES.keys
      validates :line_number, presence: true
      validates :tariff_item, presence: true, length: {is: 12}, if:->{document_type.eql?(FE::ExportInvoice::DOCUMENT_TYPE) && !SERVICE_UNITS.include?(unit) && document.version_43? }
      validates :quantity, presence: true, numericality: { greater_than: 0 }
      validates :unit, presence: true, inclusion: UNITS
      validates :description, presence: true, length: { maximum: 200 }
      validates :unit_price, presence: true
      validates :total, presence: true
      validates :discount, numericality: { grater_than: 0 }, if: -> { discount.present? }
      validates :discount_reason, presence: true, if: -> { discount.present? }
      validates :subtotal, presence: true
      validates :taxable_base, presence: true, if: ->{ taxes.map{ |t| t.code.eql?("07")}.include?(true) && document.version_43? }
      validates :net_tax,presence:true, if: ->{ exoneration.present? }
      validates :net_total, presence: true
      validates :comercial_code_type, inclusion: CODE_TYPES.keys, if: -> { comercial_code.present? }
      validates :comercial_code, presence: true, length: {maximum: 20}
      validates :code, length: {maximum: 13} #TODO this will be mandatory after 2020-01-01

      validate :calculations_ok?

      def initialize(args = {})
        @document_type = args[:document_type]
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

      def build_xml(node, document)
        @document = document
        @document_type = document.document_type
        raise FE::Error.new("item invalid",class: self.class, messages: errors.messages) unless valid?

        node = Nokogiri::XML::Builder.new if node.nil?
        node.LineaDetalle do |x|
          x.NumeroLinea @line_number

          x.PartidaArancelaria @tariff_item if @tariff_item.present? && document.version_43?

          if document.version_43?
            x.Codigo @code if @code.present?
          end

          if @comercial_code.present? && document.version_43?
            x.CodigoComercial do |x2|
              x2.Tipo @comercial_code_type
              x2.Codigo @comercial_code
            end
          end

          if @comercial_code.present? && document.version_42?
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

          if document.version_42?
            x.MontoDescuento @discount if @discount.present?
            x.NaturalezaDescuento @discount_reason if @discount_reason.present?
          end
          if @discount.present? && document.version_43?
            x.Descuento do |x2|
              x2.MontoDescuento @discount
              x2.NaturalezaDescuento @discount_reason
            end
          end

          x.SubTotal @subtotal

          x.BaseImponible @taxable_base if @taxable_base.present? && document.version_43?
          @taxes.each do |tax|
            tax.build_xml(x,document)
          end

          x.ImpuestoNeto @net_tax if @net_tax.present? && @exoneration.present?
          x.MontoTotalLinea @net_total
        end

      end



      def calculations_ok?
        errors.add :total, :invalid_amount, message: 'invalid amount' if (@total - (@quantity * @unit_price).round(5)).abs > 1
      end


    end
  end
end
