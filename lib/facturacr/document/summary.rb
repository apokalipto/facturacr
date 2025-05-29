module FE
  class Document
    class Summary < Element
      include ActiveModel::Validations

      attr_accessor :currency, :exchange_rate, :services_taxable_total, :services_exent_total, :services_exonerate_total,
                    :goods_taxable_total,:goods_exent_total,:goods_exonerate_total, :taxable_total, :exent_total,:exonerate_total,
                    :subtotal, :discount_total, :gross_total, :tax_total,:total_iva_returned,:total_other_charges, :net_total,
                    :with_credit_card, :document_type, :has_exoneration, :medical_services_condition,:services_no_taxable_total,:goods_no_taxable_total,:no_taxable_total,:tax_summary

      validates :currency, presence: true
      validates :exchange_rate, presence: true, if: -> { currency.present? && currency != "CRC" }

      validates :services_exonerate_total, presence: true, if: -> { document.version_43? && !document_type.eql?(FE::ExportInvoice::DOCUMENT_TYPE) && has_exoneration}
      validates :goods_exonerate_total, presence: true, if: -> { document.version_43? && !document_type.eql?(FE::ExportInvoice::DOCUMENT_TYPE) && has_exoneration}
      validates :exonerate_total, presence: true, if: -> { document.version_43? && !document_type.eql?(FE::ExportInvoice::DOCUMENT_TYPE) && has_exoneration}

      validates :total_iva_returned, presence: true, if: -> { document.version_43? && medical_services_condition }
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
        @total_other_charges = args[:total_other_charges].to_f
        @net_total = args[:net_total].to_f
        @has_exoneration = args[:has_exoneration] || false
        @medical_services_condition = args[:medical_services_condition] || false
        @services_no_taxable_total = args[:services_no_taxable_total].to_f
        @goods_no_taxable_total = args[:goods_no_taxable_total].to_f
        @no_taxable_total = args[:no_taxable_total].to_f
        @tax_summary = args[:tax_summary]
        @tax_summary = [@tax_summary] if !@tax_summary.is_a?(Array)
        @payment_methods = args[:payment_methods]
        @payment_methods = [@payment_methods] if @payment_methods.present? && !@payment_methods.is_a?(Array)

      end

      def build_xml(node, document)
        @document = document
        @document_type = document.document_type
        raise FE::Error.new("summary invalid: #{ errors.messages.map{|k,v| "#{k}=#{v.join(". ")}"}.join("; ")}",class: self.class, messages: errors.messages) unless valid?
        node = Nokogiri::XML::Builder.new if node.nil?

        node.ResumenFactura do |xml|
          if document.version_42?
            xml.CodigoMoneda @currency if @currency.present?
            xml.TipoCambio @exchange_rate if @exchange_rate.present?
          elsif (document.version_43? || document.version_44?) && @currency.present?
            xml.CodigoTipoMoneda do |x|
              x.CodigoMoneda @currency
              x.TipoCambio @exchange_rate || 1
            end
          end

          xml.TotalServGravados @services_taxable_total
          xml.TotalServExentos @services_exent_total
          xml.TotalServExonerado @services_exonerate_total if @services_exonerate_total && (document.version_43? || document.version_44?) && !document_type.eql?(FE::ExportInvoice::DOCUMENT_TYPE)
          xml.TotalServNoSujeto @services_no_taxable_total if @services_no_taxable_total && document.version_44? && !document_type.eql?(FE::ExportInvoice::DOCUMENT_TYPE)
          xml.TotalMercanciasGravadas @goods_taxable_total
          xml.TotalMercanciasExentas @goods_exent_total
          xml.TotalMercExonerada @goods_exonerate_total if @goods_exonerate_total.present? && (document.version_43? || document.version_44?) && !document_type.eql?(FE::ExportInvoice::DOCUMENT_TYPE)
          xml.TotalMercNoSujeta @goods_no_taxable_total if @goods_no_taxable_total && document.version_44? && !document_type.eql?(FE::ExportInvoice::DOCUMENT_TYPE)
          xml.TotalGravado @taxable_total
          xml.TotalExento @exent_total
          xml.TotalExonerado @exonerate_total if @exonerate_total.present? && (document.version_43? || document.version_44?) && !document_type.eql?(FE::ExportInvoice::DOCUMENT_TYPE)
          xml.TotalNoSujeto @no_taxable_total if @no_taxable_total && document.version_44? && !document_type.eql?(FE::ExportInvoice::DOCUMENT_TYPE)
          xml.TotalVenta @subtotal
          xml.TotalDescuentos @discount_total
          xml.TotalVentaNeta @gross_total
          if document.version_44? && !@tax_summary.blank?
            @tax_summary.each do |tax|
              tax.build_xml(xml,document) if tax.present?
            end
          end

          xml.TotalImpuesto @tax_total
          if document.version_43? || document.version_44?
            xml.TotalIVADevuelto @total_iva_returned if @medical_services_condition && !document_type.eql?(FE::ExportInvoice::DOCUMENT_TYPE) && !document_type.eql?(FE::PurchaseInvoice::DOCUMENT_TYPE)
            xml.TotalOtrosCargos @total_other_charges if @total_other_charges > 0
          end
          if document.version_44? && @payment_methods.present?
            puts "aksjdbaskdbakjsdbjasd".green
            puts "aksjdbaskdbakjsdbjasd".green
            puts "aksjdbaskdbakjsdbjasd".green
            puts "aksjdbaskdbakjsdbjasd".green
            puts "aksjdbaskdbakjsdbjasd".green
            puts "aksjdbaskdbakjsdbjasd".green
            ap @payment_methods
            @payment_methods.each do |p|
              p.build_xml(node,document)
            end
          end
          xml.TotalComprobante @net_total
        end
      end

      private

      def totals_ok?
        errors.add :taxable_total, :invalid_amount, message: 'invalid amount' if (@taxable_total - (@services_taxable_total + @goods_taxable_total).round(5)).abs > 0.0005
        errors.add :exent_total, :invalid_amount, message: 'invalid amount' if (@exent_total - (@services_exent_total + @goods_exent_total).round(5)).abs > 0.0005
        if document.version_43?
          errors.add :exonerate_total, :invalid_amount, message: 'invalid amount' if (@exonerate_total - (@services_exonerate_total + @goods_exonerate_total).round(5)).abs > 0.0005
        end
        errors.add :subtotal, :invalid_amount, message: 'invalid amount' if (@subtotal - (@taxable_total + @exent_total + @exonerate_total ).round(5)).abs > 0.0005
        errors.add :gross_total, :invalid_amount, message: 'invalid amount' if (@gross_total - (@subtotal - @discount_total).round(5)).abs > 0.0005
        errors.add :net_total, :invalid_amount, message: "invalid amount" if (@net_total - (@gross_total + @tax_total + @total_other_charges - @total_iva_returned).round(5)).abs > 0.0005
      end
    end
  end
end
