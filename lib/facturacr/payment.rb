require_relative 'document'

module FE

  class Payment < Document
    NAMESPACES ={
      "4.4" => {
        "xmlns:xsi"=>"http://www.w3.org/2001/XMLSchema-instance",
        "xmlns:xsd"=>"http://www.w3.org/2001/XMLSchema",
        "xmlns"=>"https://cdn.comprobanteselectronicos.go.cr/xml-schemas/v4.4/reciboElectronicoPago"#,
      }}
    CONDITIONS = {
      "09"=>"Pago del servicios prestado al Estado ",
      "11"=>"Pago de venta a crédito en IVA hasta 90 días (Artículo 27,LIVA)"
    }.freeze

    validates :receiver, presence: true
    validates :condition, presence: true, inclusion: CONDITIONS.keys


    DOCUMENT_TYPE = "10"
    def initialize(args={})
      @version = args[:version]

      @date = args[:date]
      @issuer = args[:issuer]
      @receiver = args[:receiver]
      @items = args[:items]
      @number = args[:number]
      @condition = args[:condition] || "09"
      @document_type = DOCUMENT_TYPE
      @summary = args[:summary]
      @regulation = args[:regulation] ||= FE::Document::Regulation.new
      @security_code = args[:security_code]
      @document_situation = args[:document_situation]
      @namespaces = NAMESPACES[@version]
      @references = args[:references] || []
      @software_supplier = args[:software_supplier]
      @other_condition = args[:other_condition]
    end

    def document_tag
      "ReciboElectronicoPago"
    end

  end
end
