require 'facturacr/document/regulation'
module FE

  class CreditNote < Document
    NAMESPACES ={
      "4.2" => {
      "xmlns:xsi"=>"http://www.w3.org/2001/XMLSchema-instance",
      "xmlns:xsd"=>"http://www.w3.org/2001/XMLSchema",
      "xmlns"=>"https://tribunet.hacienda.go.cr/docs/esquemas/2017/v4.2/notaCreditoElectronica"#,
      },
      "4.3" => {
        "xmlns:xsi"=>"http://www.w3.org/2001/XMLSchema-instance",
        "xmlns:xsd"=>"http://www.w3.org/2001/XMLSchema",
        "xmlns"=>"https://cdn.comprobanteselectronicos.go.cr/xml-schemas/v4.3/notaCreditoElectronica"#,
      },
      "4.4" => {
        "xmlns:xsi"=>"http://www.w3.org/2001/XMLSchema-instance",
        "xmlns:xsd"=>"http://www.w3.org/2001/XMLSchema",
        "xmlns"=>"https://cdn.comprobanteselectronicos.go.cr/xml-schemas/v4.4/notaCreditoElectronica"#,
      }
    }
    DOCUMENT_TYPE = "03"
    def initialize(args={})
      @version = args[:version]
      @economic_activity = args[:economic_activity]
      @date = args[:date]
      @issuer = args[:issuer]
      @receiver = args[:receiver]
      @items = args[:items]
      @number = args[:number]
      @condition = args[:condition]
      @payment_type = args[:payment_type] || ["01"]
      @document_type = DOCUMENT_TYPE
      @credit_term = args[:credit_term]
      @summary = args[:summary]
      @regulation = args[:regulation] ||= FE::Document::Regulation.new
      @security_code = args[:security_code]
      @document_situation = args[:document_situation]
      @references = args[:references]
      @other_charges = args[:other_charges]
      @namespaces = NAMESPACES[@version]
      @others = args[:others] || []
      @software_supplier = args[:software_supplier]
      @receiver_economic_activity = args[:receiver_economic_activity]
      @other_condition = args[:other_condition]
    end

    def document_tag
      "NotaCreditoElectronica"
    end

  end
end
