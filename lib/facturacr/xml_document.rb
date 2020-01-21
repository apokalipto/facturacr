require 'nokogiri'

require 'facturacr/document'

module FE  
  class XmlDocument
    
    attr_accessor :document, :root_tag, :doc, :xml
    
    def initialize(xml_provider)
      # Backwards compatibility with v0.1.4
      if xml_provider.is_a?(String)
        raise ArgumentError, "File: #{xml_provider} does not exist" unless File.exists?(xml_provider)
        xml_provider = FE::DataProvider.new(:file, xml_provider)
      end
      raise ArgumentError, "Invalid Argument" unless xml_provider.is_a?(FE::DataProvider)
      @xml = xml_provider.contents
      @doc = Nokogiri::XML(@xml) do |config|
        config.options = Nokogiri::XML::ParseOptions::NOBLANKS | Nokogiri::XML::ParseOptions::NOENT
      end
      root_tag = @doc.elements.first.name
      
      if root_tag.eql?('FacturaElectronica')
        @document = FE::Invoice.new
      elsif root_tag.eql?("NotaCreditoElectronica")
        @document = FE::CreditNote.new
      elsif root_tag.eql?("NotaDebitoElectronica")
        @document = FE::DebitNote.new
      elsif root_tag.eql?("TiqueteElectronico")
        @document = FE::Ticket.new
      elsif root_tag.eql?("MensajeReceptor")
        @document = FE::ReceptionMessage.new
      else
        @document = nil
      end

      if @document.is_a?(FE::Document)
        @document.version = @doc.elements.first.namespace.href.scan(/v4\..{1}/).first[1..-1]
        @document.date = DateTime.parse(@doc.css("#{root_tag} FechaEmision").first&.text)
        if @document.version_43?
          @document.economic_activity = @doc.css("#{root_tag} CodigoActividad").text
        end
        @key = @doc.css("#{root_tag} Clave").text
        @document.key = @key if @key.present?
        @document.headquarters = @key[21..23]
        @document.terminal = @key[24..28]
        @document.number = @key[31..40].to_i
        @document.document_situation = @key[41]
        @document.security_code = @key[42..-1]
        @document.condition = @doc.css("#{root_tag} CondicionVenta").text
        @document.credit_term = @doc.css("#{root_tag} PlazoCredito").text unless @doc.css("#{root_tag} PlazoCredito").empty?
        @document.payment_type = @doc.css("#{root_tag} MedioPago").first.text
        @issuer = FE::Document::Issuer.new
        @issuer.identification_document = FE::Document::IdentificationDocument.new type: @doc.css("#{root_tag} Emisor Identificacion Tipo").text, number: @doc.css("#{root_tag} Emisor Identificacion Numero").text.to_i
        @issuer.name = @doc.css("#{root_tag} Emisor Nombre").text
        @issuer.comercial_name = @doc.css("#{root_tag} Emisor NombreComercial").text unless @doc.css("#{root_tag} Emisor NombreComercial").empty?
        location = FE::Document::Location.new
        location.province = @doc.css("#{root_tag} Emisor Ubicacion Provincia").text
        location.county = @doc.css("#{root_tag} Emisor Ubicacion Canton").text
        location.district = @doc.css("#{root_tag} Emisor Ubicacion Distrito").text
        location.others = @doc.css("#{root_tag} Emisor Ubicacion OtrasSenas").text
        @issuer.location = location
      
        if !@doc.css("#{root_tag} Emisor Telefono").empty?
          @issuer.phone = FE::Document::Phone.new country_code: @doc.css("#{root_tag} Emisor Telefono CodigoPais").text, number: @doc.css("#{root_tag} Emisor Telefono CodigoPais").text
        end
        if !@doc.css("#{root_tag} Emisor Fax").empty?
          @issuer.fax = FE::Document::Phone.new country_code: @doc.css("#{root_tag} Emisor Telefono CodigoPais").text, number: @doc.css("#{root_tag} Emisor Telefono CodigoPais").text
        end
        @issuer.email = @doc.css("#{root_tag} Emisor CorreoElectronico").text
      
        unless @doc.css("#{root_tag} Receptor").empty?
          @receiver = FE::Document::Receiver.new
          @receiver.name = @doc.css("#{root_tag} Receptor Nombre").text
          unless @doc.css("#{root_tag} Receptor Identificacion").empty?
            @receiver.identification_document = FE::Document::IdentificationDocument.new type: @doc.css("#{root_tag} Receptor Identificacion Tipo").text, number: @doc.css("#{root_tag} Receptor Identificacion Numero").text.to_i
          end
        
          unless @doc.css("#{root_tag} Receptor IdentificacionExtranjero").empty?
            @receiver.foreign_id_number = @doc.css("#{root_tag} Receptor IdentificacionExtranjero").text
          end
          @receiver.comercial_name = @doc.css("#{root_tag} Receptor NombreComercial").text unless @doc.css("#{root_tag} Receptor NombreComercial").empty?
        
          unless @doc.css("#{root_tag} Receptor Ubicacion").empty?
            location = FE::Document::Location.new
            location.province = @doc.css("#{root_tag} Receptor Ubicacion Provincia").text
            location.county = @doc.css("#{root_tag} Receptor Ubicacion Canton").text
            location.district = @doc.css("#{root_tag} Receptor Ubicacion Distrito").text
            location.others = @doc.css("#{root_tag} Receptor Ubicacion OtrasSenas").text
            @receiver.location = location
          end
        
          if !@doc.css("#{root_tag} Receptor Telefono").empty?
            @issuer.phone = FE::Document::Phone.new country_code: @doc.css("#{root_tag} Receptor Telefono CodigoPais").text, number: @doc.css("#{root_tag} Receptor Telefono CodigoPais").text
          end
          if !@doc.css("#{root_tag} Receptor Fax").empty?
            @receiver.fax = FE::Document::Phone.new country_code: @doc.css("#{root_tag} Receptor Telefono CodigoPais").text, number: @doc.css("#{root_tag} Receptor Telefono CodigoPais").text
          end
          @receiver.email = @doc.css("#{root_tag} Receptor CorreoElectronico").text unless @doc.css("#{root_tag} Receptor CorreoElectronico").empty?
        end
        @items = []
        @doc.css("#{root_tag} DetalleServicio LineaDetalle").each do |line|
          item = FE::Document::Item.new
          item.line_number = line.css("NumeroLinea").text.to_i
          if @document.version_42?
            item.code = line.css("Codigo Codigo").text
          elsif @document.version_43?
            item.code = line.css("CodigoComercial Codigo").text
          end
          item.quantity = line.css("Cantidad").text
          item.unit = line.css("UnidadMedida").text
          item.description = line.css("Detalle").text
          item.unit_price = line.css("PrecioUnitario").text.to_f
          item.total = line.css("MontoTotal").text.to_f
          item.discount = line.css("MontoDescuento").text.to_f unless line.css("MontoDescuento").empty?
          item.discount_reason = line.css("NaturalezaDescuento").text unless line.css("NaturalezaDescuento").empty?
          item.subtotal = line.css("SubTotal").text.to_f
          item.net_total = line.css("MontoTotalLinea").text.to_f
          item.taxes = []
          line.css("Impuesto").each do |tax|
            exo = nil
            t_args = {code: tax.css("Codigo").text, rate: tax.css("Tarifa").text.to_f, total: tax.css("Monto").text.to_f}
            unless tax.css("Exoneracion").empty?
              exo = FE::Document::Exoneration.new
              exo.document_type = line.css("Exoneracion TipoDocumento").text
              exo.document_number = line.css("Exoneracion NumeroDocumento").text
              exo.institution = line.css("Exoneracion NombreInstitucion").text
              exo.date = DateTime.parse(line.css("Exoneracion FechaEmision").text)
              exo.total_tax = line.css("Exoneracion MontoImpuesto").text.to_f
              exo.percentage = line.css("Exoneracion PorcentajeCompra").text.to_i
              t_args[:exoneration] = exo
            end
            
            item.taxes << FE::Document::Tax.new(t_args)
          end
          @items << item
        end

      
        @summary = FE::Document::Summary.new
        sum = @doc.css("#{root_tag} ResumenFactura")
        if @document.version_42?
          @summary.currency = sum.css("CodigoMoneda").text
          @summary.exchange_rate = sum.css("TipoCambio").text.to_f
        elsif @document.version_43?
          @summary.currency = sum.css("CodigoTipoMoneda CodigoMoneda").text
          @summary.exchange_rate = sum.css("CodigoTipoMoneda TipoCambio").text.to_f
        end
        @summary.services_taxable_total = sum.css("TotalServGravados").text.to_f
        @summary.services_exent_total = sum.css("TotalServExentos").text.to_f
        @summary.goods_taxable_total = sum.css("TotalMercanciasGravadas").text.to_f
        @summary.goods_exent_total = sum.css("TotalMercanciasExentas").text.to_f
        @summary.taxable_total = sum.css("TotalGravado").text.to_f
        @summary.exent_total = sum.css("TotalExento").text.to_f
        @summary.subtotal = sum.css("TotalVenta").text.to_f
        @summary.discount_total = sum.css("TotalDescuentos").text.to_f
        @summary.gross_total = sum.css("TotalVentaNeta").text.to_f
        @summary.tax_total = sum.css("TotalImpuesto").text.to_f
        @summary.net_total = sum.css("TotalComprobante").text.to_f
      
        refs = @doc.css("#{root_tag} InformacionReferencia")
        @references = []
        unless refs.empty?
          refs.each do |ref|
            reference = FE::Document::Reference.new
            reference.document_type = ref.css("TipoDoc")
            reference.number = ref.css("Numero")
            reference.date = ref.css("FechaEmision")
            reference.code = ref.css("Codigo")
            reference.reason = ref.css("Razon")
            @references << reference
          end
        end
      
        reg = @doc.css("#{root_tag} Normativa")
        @regulation = FE::Document::Regulation.new
        @regulation.number = reg.css("NumeroResolucion").text
        @regulation.date = reg.css("FechaResolucion").text
      
      
        @document.issuer = @issuer
        @document.receiver = @receiver
        @document.items = @items
        @document.summary = @summary
        @document.references = @references
        @document.regulation = @regulation  
      elsif @document.present?
        @document.date = DateTime.parse(@doc.css("#{root_tag} FechaEmisionDoc").text)
        @key = @doc.css("#{root_tag} Clave").text
        @document.key = @key
        @document.issuer_id_number = @doc.css("#{root_tag} NumeroCedulaEmisor").text
        @document.receiver_id_number = @doc.css("#{root_tag} NumeroCedulaReceptor").text
        @document.message = @doc.css("#{root_tag} Mensaje").text
        @document.details = @doc.css("#{root_tag} DetalleMensaje").text
        @document.number = @doc.css("#{root_tag} NumeroConsecutivoReceptor").text[10..-1].to_i
        @document.document_situation = @key[41]
        @document.security_code = @key[42..-1]
        @document.total = @doc.css("#{root_tag} TotalFactura").text
        @document.tax = @doc.css("#{root_tag} MontoTotalImpuesto").text
      end      
    end
    
    def has_tax_node?
      @doc.css("#{root_tag} ResumenFactura TotalImpuesto").any?
    end
  end
end