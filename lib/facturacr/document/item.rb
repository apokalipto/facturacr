module FE
  class Document
    class Item < Element
      include ActiveModel::Validations

      UNITS = %w[ Al Alc Cm I Os Spe St Sp m kg s A K mol cd m² m³ m/s m/s² 1/m kg/m³ A/m² A/m mol/m³ cd/m² 1 rad sr Hz N Pa J W C V F Ω S Wb T H °C lm
                 lx Bq Gy Sv kat Pa·s N·m N/m rad/s rad/s² W/m² J/K J/(kg·K) J/kg W/(m·K) J/m³ V/m C/m³ C/m² F/m H/m J/mol J/(mol·K)
                 C/kg Gy/s W/sr W/(m²·sr) kat/m³ min h d º ´ ´´ L t Np B eV u ua Unid Gal g Km ln cm mL mm Oz Otros].freeze
      SERVICE_UNITS = %w[Al Alc Os Spe Sp St min h I Cm].freeze
      CODE_TYPES = {
        '01' => 'Código del producto del vendedor',
        '02' => 'Código del producto del comprador',
        '03' => 'Código del producto asignado por la industria',
        '04' => 'Código uso interno',
        '99' => 'Otros'
      }.freeze

      TRANSACTION_TYPES = {
        '01' => 'Venta Normal de Bienes y Servicios (Transacción General)',
        '02' => 'Mercancía de Autoconsumo exento',
        '03' => 'Mercancía de Autoconsumo gravado',
        '04' => 'Servicio de Autoconsumo exento',
        '05' => 'Servicio de Autoconsumo gravado',
        '06' => 'Cuota de afiliación',
        '07' => 'Cuota de afiliación Exenta',
        '08' => 'Bienes de Capital para el emisor',
        '09' => 'Bienes de Capital para el receptor',
        '10' => 'Bienes de Capital para para el emisor y el receptor',
        '11' => 'Bienes de capital de autoconsumo exento para el emisor',
        '12' => 'Bienes de capital sin contraprestación a terceros exento para el emisor',
        '13' => 'Sin contraprestación a terceros'
      }.freeze

      DISCOUNT_CODES = {
        '01' => 'Descuento por Regalía',
        '02' => 'Descuento por Regalía IVA Cobrado al Cliente',
        '03' => 'Descuento por Bonificación',
        '04' => 'Descuento por volumen',
        '05' => 'Descuento por Temporada(estacional)',
        '06' => 'Descuento promocional',
        '07' => 'Descuento Comercial',
        '08' => 'Descuento por frecuencia',
        '09' => 'Descuento sostenido',
        '99' => 'Otros descuentos'
      }.freeze

      attr_accessor :line_number,:tariff_item,:code, :skip_code_validation, :comercial_code_type, :comercial_code, :quantity, :unit, :description, :unit_price, :total,
                    :discount, :discount_reason,:discount_code,:discount_code_reason, :subtotal,:taxable_base ,:taxes,:net_tax ,:net_total, :exoneration, :document_type,
                    :transaction_type,:combo_items,:vin_number,:tax_assumed_by_factory_issuer

      validates :document_type, presence: true, inclusion: FE::Document::DOCUMENT_TYPES.keys
      validates :line_number, presence: true
      validates :tariff_item, presence: true, length: {is: 12}, if:->{document_type.eql?(FE::ExportInvoice::DOCUMENT_TYPE) && !SERVICE_UNITS.include?(unit) && document.version_43? }
      validates :quantity, presence: true, numericality: { greater_than_or_equal_to: 0 }
      validates :unit, presence: true, inclusion: UNITS
      validates :description, presence: true, length: { maximum: 200 }
      validates :unit_price, presence: true
      validates :total, presence: true
      validates :discount, numericality: { grater_than: 0 }, if: -> { discount.present? }
      validates :discount_reason, presence: true, if: -> { discount.present? }
      validates :discount_code_reason, presence: true, if: -> { discount.present? && discount_code.eql?("99") && document.version_44?}
      validates :subtotal, presence: true
      validates :taxable_base, presence: true, if: ->{ taxes.map{ |t| t.code.eql?("07")}.include?(true) && document.version_43? }
      validates :net_tax,presence:true, if: ->{ taxes.map{ |t| t.exoneration.present? }.include?(true) }
      validates :net_total, presence: true
      validates :comercial_code_type, inclusion: CODE_TYPES.keys, if: -> { comercial_code.present? }
      validates :comercial_code, presence: true, length: {maximum: 20}
      validates :code, presence: true, length: {maximum: 13}, if: :code_is_mandatory?
      validates :transaction_type, length: {is: 2}, if: -> {transaction_type.present? && document.version_44? }
      validates :transaction_type, inclusion: TRANSACTION_TYPES.keys, if: -> {transaction_type.present? && document.version_44?  }
      validates :combo_items, length: { minimum: 1, maximum: 20 }, if: ->{combo_items.present? && document.version_44?}

      validate :calculations_ok?

      def initialize(args = {})
        @document_type = args[:document_type]
        @line_number = args[:line_number]
        @code = args[:code]
        @skip_code_validation = args[:skip_code_validation]
        @comercial_code_type = args[:comercial_code_type].presence || '01'
        @comercial_code = args[:comercial_code]
        @quantity = args[:quantity]
        @unit = args[:unit]
        @description = args[:description]
        @unit_price = args[:unit_price]
        @total = args[:total]
        @discount = args[:discount]
        @discount_reason = args[:discount_reason]
        @discount_code = args[:discount_code] || "01"
        @discount_code_reason = args[:discount_code_reason]
        @subtotal = args[:subtotal]
        @taxes = args[:taxes] || []
        @net_total = args[:net_total]
        @exoneration = args[:exoneration]
        @net_tax = args[:net_tax]
        @tariff_item = args[:tariff_item]
        @taxable_base = args[:taxable_base]
        @issued_date = args[:issued_date]
        @transaction_type = args[:transaction_type] || "01"
        @combo_items = args[:combo_items]
        @combo_items = [args[:combo_items]] if args[:combo_items].is_a?(Hash)
        @vin_number = args[:vin_number]
        @tax_assumed_by_factory_issuer = args[:tax_assumed_by_factory_issuer]
      end

      def build_xml(node, document)
        @document = document
        @document_type = document.document_type
        raise FE::Error.new("item invalid: #{ errors.messages.map{|k,v| "#{k}=#{v.join(". ")}" }.join('; ')}",class: self.class, messages: errors.messages) unless valid?

        node = Nokogiri::XML::Builder.new if node.nil?
        node.LineaDetalle do |x|
          x.NumeroLinea @line_number

          x.PartidaArancelaria @tariff_item if @tariff_item.present? && document.version_43?

          if document.version_43?
            x.Codigo @code if @code.present?
          end

          if document.version_44?
            x.CodigoCABYS @code if @code.present?
          end

          if @comercial_code.present? && (document.version_43? || document.version_44?)
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
          x.TipoTransaccion @transaction_type if document.version_44? && @transaction_type.present? && !@document_type.eql?(FE::Ticket::DOCUMENT_TYPE)
          x.Detalle @description
          x.NumeroVINoSerie @vin_number if document.version_44? && @vin_number.present?

          if document.version_44? && @combo_items.present?
            x.DetalleSurtido do |x2|
              @combo_items.each do |combo_item|
                combo_item.build_combo_item(x2,@document)
              end
            end
          end

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

          if @discount.present? && document.version_44?
            x.Descuento do |x2|
              x2.MontoDescuento @discount
              x2.CodigoDescuento @discount_code
              x2.CodigoDescuentoOTRO @discount_code_reason if @discount_code_reason.present?
              x2.NaturalezaDescuento @discount_reason
            end
          end

          x.SubTotal @subtotal

          x.BaseImponible @taxable_base if @taxable_base.present? && (document.version_43? ||document.version_44? )
          @taxes.each do |tax|
            tax.build_xml(x,document)
          end

          x.ImpuestoAsumidoEmisorFabrica @tax_assumed_by_factory_issuer if document.version_44? && @tax_assumed_by_factory_issuer.present? && ![FE::ExportInvoice::DOCUMENT_TYPE,FE::PurchaseInvoice::DOCUMENT_TYPE].include?(@document_type)
          x.ImpuestoNeto @net_tax if @net_tax.present? && document.version_43?
          x.ImpuestoNeto @net_tax if @net_tax.present? && document.version_44? && ![FE::ExportInvoice::DOCUMENT_TYPE].include?(@document_type)
          x.MontoTotalLinea @net_total
        end

      end

      def build_combo_item(node,document)
        @document = document
        @document_type = document.document_type
        raise FE::Error.new("item invalid: #{ errors.messages.map{|k,v| "#{k}=#{v.join(". ")}" }.join('; ')}",class: self.class, messages: errors.messages) unless valid?

        node = Nokogiri::XML::Builder.new if node.nil?
        node.LineaDetalleSurtido do |x|
          x.CodigoCABYSSurtido @code if @code.present?

          x.CodigoComercialSurtido do |x2|
            x2.TipoSurtido @comercial_code_type
            x2.CodigoSurtido @comercial_code
          end

          x.CantidadSurtido @quantity
          x.UnidadMedidaSurtido @unit
          x.DetalleSurtido @description
          x.PrecioUnitarioSurtido @unit_price
          x.MontoTotalSurtido @total


          if @discount.present?
            x.DescuentoSurtido do |x2|
              x2.MontoDescuentoSurtido @discount
              x2.CodigoDescuentoSurtido @discount_code
              x2.DescuentoSurtidoOtros @discount_code_reason
            end
          end

          x.SubTotalSurtido @subtotal

          x.BaseImponibleSurtido @taxable_base if @taxable_base.present? && document.version_44?
          @taxes.each do |tax|
            tax.build_combo_item(x,document)
          end
          x.ImpuestoNeto @net_tax if @net_tax.present?
          x.MontoTotalLinea @net_total
        end
      end

      def calculations_ok?
        errors.add :total, :invalid_amount, message: 'invalid amount' if (@total - (@quantity * @unit_price).round(5)).abs > 1
      end

      def code_is_mandatory?
        if !@skip_code_validation.present? || !@skip_code_validation
          if Time.zone.now >= Time.zone.parse("2020-12-01").beginning_of_day
            if @issued_date.present? && @issued_date < Time.zone.parse("2020-12-01").beginning_of_day
              false
            else
              true
            end
          else
            false
          end
        else
          false
        end
      end
    end
  end
end
