require 'facturacr/document'

module FE

  class ExportInvoice < Document

    NAMESPACES ={
      "4.3" => {
        "xmlns:xsi"=>"http://www.w3.org/2001/XMLSchema-instance",
        "xmlns:xsd"=>"http://www.w3.org/2001/XMLSchema",
        "xmlns"=>"https://cdn.comprobanteselectronicos.go.cr/xml-schemas/v4.3/facturaElectronicaExportacion"#,
      },
      "4.4" => {
        "xmlns:xsi"=>"http://www.w3.org/2001/XMLSchema-instance",
        "xmlns:xsd"=>"http://www.w3.org/2001/XMLSchema",
        "xmlns"=>"https://cdn.comprobanteselectronicos.go.cr/xml-schemas/v4.4/facturaElectronicaExportacion"#,
      }}
    DOCUMENT_TYPE = "09"

    validates :receiver, presence: true, if: -> { version.eql?("4.3") }


    def initialize(args={})
      @version = args[:version]
      @economic_activity = args[:economic_activity]
      @date = args[:date]
      @issuer = args[:issuer]
      @receiver = args[:receiver]
      @items = args[:items]
      @number = args[:number]
      @condition = args[:condition]
      @payment_type = args[:payment_type] || ["01"] if version.eql?("4.3")
      @document_type = DOCUMENT_TYPE
      @credit_term = args[:credit_term]
      @summary = args[:summary]
      @security_code = args[:security_code]
      @document_situation = args[:document_situation]
      @other_charges = args[:other_charges]
      @namespaces = NAMESPACES[@version]
      @others = args[:others] || []
      @software_supplier = args[:software_supplier]
      @other_condition = args[:other_condition]
    end

    def document_tag
      "FacturaElectronicaExportacion"
    end

  end
end
