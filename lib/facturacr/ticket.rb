require 'facturacr/document'

module FE

  class Ticket < Document
    NAMESPACES ={
      "4.2" => {
      "xmlns:xsi"=>"http://www.w3.org/2001/XMLSchema-instance",
      "xmlns:xsd"=>"http://www.w3.org/2001/XMLSchema",
      "xmlns"=>"https://tribunet.hacienda.go.cr/docs/esquemas/2017/v4.2/tiqueteElectronico"
      },
      "4.3" => {
        "xmlns:xsi"=>"http://www.w3.org/2001/XMLSchema-instance",
        "xmlns:xsd"=>"http://www.w3.org/2001/XMLSchema",
        "xmlns"=>"https://cdn.comprobanteselectronicos.go.cr/xml-schemas/v4.3/tiqueteElectronico"#,
      },
      "4.4" => {
        "xmlns:xsi"=>"http://www.w3.org/2001/XMLSchema-instance",
        "xmlns:xsd"=>"http://www.w3.org/2001/XMLSchema",
        "xmlns"=>"https://cdn.comprobanteselectronicos.go.cr/xml-schemas/v4.4/tiqueteElectronico"#,
      }
    }
    DOCUMENT_TYPE = "04"

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
      @other_charges = args[:other_charges]
      @regulation = args[:regulation] ||= FE::Document::Regulation.new
      @security_code = args[:security_code]
      @document_situation = args[:document_situation]
      @namespaces = NAMESPACES[@version]
      @others = args[:others] || []
      @references = args[:references] || []
      @software_supplier = args[:software_supplier]
      @other_condition = args[:other_condition]
    end

    def document_tag
      "TiqueteElectronico"
    end

  end
end
