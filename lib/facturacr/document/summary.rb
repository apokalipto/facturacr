module FE
  class Document
    class Summary
      include ActiveModel::Validations
      
      attr_accessor :currency, :exchange_rate, :services_taxable_total, :services_exent_total, 
                    :goods_taxable_total,:goods_exent_total, :taxable_total, :exent_total,
                    :subtotal, :discount_total, :gross_total, :tax_total, :net_total
      
      validates :exchange_rate, presence: true, if: -> { currency.present? }
      
      validate :totals_ok?
                    
      def initialize(args={})
        @currency = args[:currency]
        @exchange_rate = args[:exchange_rate]
        @services_taxable_total = args[:services_taxable_total].to_f
        @services_exent_total = args[:services_exent_total].to_f
        @goods_taxable_total = args[:goods_taxable_total].to_f
        @goods_exent_total = args[:goods_exent_total].to_f
        @taxable_total = args[:taxable_total].to_f
        @exent_total = args[:exent_total].to_f
        @subtotal = args[:subtotal].to_f
        @discount_total = args[:discount_total].to_f
        @gross_total = args[:gross_total].to_f
        @tax_total = args[:tax_total].to_f
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
          xml.TotalMercanciasGravadas @goods_taxable_total
          xml.TotalMercanciasExentas @goods_exent_total
          xml.TotalGravado @taxable_total
          xml.TotalExento @exent_total
          xml.TotalVenta @subtotal
          xml.TotalDescuentos @discount_total
          xml.TotalVentaNeta @gross_total
          xml.TotalImpuesto @tax_total
          xml.TotalComprobante @net_total
        end
      end
      
      private
      
      def totals_ok?
        errors[:taxable_total] << "invalid amount" if (@taxable_total - (@services_taxable_total + @goods_taxable_total).round(5)).abs > 0.0001
        errors[:exent_total] << "invalid amount" if (@exent_total - (@services_exent_total + @goods_exent_total).round(5)).abs > 0.0001
        errors[:subtotal] << "invalid amount" if (@subtotal - (@taxable_total + @exent_total).round(5)).abs > 0.0001
        errors[:gross_total] << "invalid amount" if (@gross_total - (@subtotal - @discount_total).round(5)).abs > 0.0001
        errors[:net_total] << "invalid amount" if (@net_total - (@gross_total + @tax_total).round(5)).abs > 0.0001
      end
    end
  end
end