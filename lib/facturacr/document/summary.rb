module FE
  class Document
    class Summary
      include ActiveModel::Validations

      attr_accessor :currency, :exchange_rate, :services_taxable_total, :services_exent_total, :services_exonerate_total,
                    :goods_taxable_total,:goods_exent_total,:goods_exonerate_total, :taxable_total, :exent_total,:exonerate_total,
                    :subtotal, :discount_total, :gross_total, :tax_total,:total_iva_returned,:total_others_charges, :net_total,  :with_credit_card
      #TODO verificar que si la moneda es de otro pais el tipo de cambio debe estar agregado
      #validates :exchange_rate, presence: true, if: -> { currency.present? }
      validates :currency, presence: true
      validates :services_exonerate_total, presence:false, if: -> {:document_type.eql?("09") || FE.configuration.version_43?}
      validates :goods_exonerate_total, presence:false, if: -> {:document_type.eql?("09") || FE.configuration.version_43?}
      validates :exonerate_total, presence:false, if: -> {:document_type.eql?("09")|| FE.configuration.version_43?}
      #validates :total_iva_returned, presence: true, if: -> { FE.configuration.version_43? ) }
      validate :totals_ok?

      def initialize(args={})
        @currency = args[:currency]
        @exchange_rate = args[:exchange_rate]
        @services_taxable_total = args[:services_taxable_total].to_f
        @services_exent_total = args[:services_exent_total].to_f
        @services_exonerate_total = args[:services_exonerate_total].to_f
        @goods_taxable_total = args[:goods_taxable_total].to_f
        @goods_exent_total = args[:goods_exent_total].to_f
        @goods_exonerate_total = args[:goods_exonerate_total].to_f
        @taxable_total = args[:taxable_total].to_f
        @exent_total = args[:exent_total].to_f
        @exonerate_total = args[:exonerate_total].to_f
        @subtotal = args[:subtotal].to_f
        @discount_total = args[:discount_total].to_f
        @gross_total = args[:gross_total].to_f
        @tax_total = args[:tax_total].to_f
        @total_iva_returned = args[:total_iva_returned].to_f
        @total_others_charges =args[:total_others_charges].to_f
        @net_total = args[:net_total].to_f

      end

      def build_xml(node)
        unless valid?
          raise "Summary invalid: #{errors.messages}"
        end
        node = Nokogiri::XML::Builder.new if node.nil?

        node.ResumenFactura do |xml|
          xml.CodigoMoneda @currency if @currency.present?
          xml.TipoCambio @exchange_rate if @exchange_rate.present?
          xml.TotalServGravados @services_taxable_total
          xml.TotalServExentos @services_exent_total
          xml.TotalServExonerado @services_exonerate_total  if FE.configuration.version_43?
          xml.TotalMercanciasGravadas @goods_taxable_total
          xml.TotalMercanciasExentas @goods_exent_total
          xml.TotalMercanciasExoneradas @goods_exonerate_total  if FE.configuration.version_43?
          xml.TotalGravado @taxable_total
          xml.TotalExento @exent_total
          xml.TotalExonerado @exonerate_total if FE.configuration.version_43?
          xml.TotalVenta @subtotal
          xml.TotalDescuentos @discount_total
          xml.TotalVentaNeta @gross_total
          xml.TotalImpuesto @tax_total
          if FE.configuration.version_43?
            #xml.TotalIVADevuelto @total_iva_returned
            xml.TotalOtrosCargos @total_others_charges
          end
          xml.TotalComprobante @net_total
        end
      end

      private

      def totals_ok?
        errors.add :taxable_total, :invalid_amount, message: 'invalid amount' if (@taxable_total - (@services_taxable_total + @goods_taxable_total).round(5)).abs > 0.0005
        errors.add :exent_total, :invalid_amount, message: 'invalid amount' if (@exent_total - (@services_exent_total + @goods_exent_total).round(5)).abs > 0.0005
        if FE.configuration.version_43?
          errors.add :exonerate_total, :invalid_amount, message: 'invalid amount' if (@exonerate_total - (@services_exonerate_total + @goods_exonerate_total).round(5)).abs > 0.0005
        end
        errors.add :subtotal, :invalid_amount, message: 'invalid amount' if (@subtotal - (@taxable_total + @exent_total).round(5)).abs > 0.0005
        errors.add :gross_total, :invalid_amount, message: 'invalid amount' if (@gross_total - (@subtotal - @discount_total).round(5)).abs > 0.0005
        errors.add :net_total, :invalid_amount, message: 'invalid amount' if (@net_total - (@gross_total + @tax_total + @total_others_charges).round(5)).abs > 0.0005
      end
    end
  end
end
