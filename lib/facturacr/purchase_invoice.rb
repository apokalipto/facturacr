require 'facturacr/document'

module FE

  class Purchase_Invoice < Document

    validates :receiver, presence: true, if: -> { FE.configuration.version_43? }

    def initialize(args={})
      @economic_activity = args[:economic_activity]
      @date = args[:date]
      @issuer = args[:issuer]
      @receiver = args[:receiver]
      @items = args[:items]
      @number = args[:number]
      @condition = args[:condition]
      @payment_type = args[:payment_type] || "01"
      @document_type = "08"
      @credit_term = args[:credit_term]
      @summary = args[:summary]
      @security_code = args[:security_code]
      @document_situation = args[:document_situation]
      @other_charges = args[:other_charges]
      @namespaces = {
        "xmlns:xsi"=>"http://www.w3.org/2001/XMLSchema-instance",
        "xmlns:xsd"=>"http://www.w3.org/2001/XMLSchema",
        "xmlns"=>"https://cdn.comprobanteselectronicos.go.cr/xml-schemas/v4.3/facturaElectronicaExportacion"#,
      }
      @others = args[:others] || []
    end

    def document_tag
      "FacturaElectronicaCompra"
    end

  end
end
