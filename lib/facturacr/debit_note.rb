require 'facturacr/document/regulation'
module FE
 
  class DebitNote < Document
    
    def initialize(args={})
      @date = args[:date]
      @issuer = args[:issuer]
      @receiver = args[:receiver]
      @items = args[:items]
      @number = args[:number]
      @condition = args[:condition]
      @payment_type = args[:payment_type] || "01"
      @document_type = "02"
      @credit_term = args[:credit_term]
      @summary = args[:summary]
      @regulation = args[:regulation] ||= FE::Document::Regulation.new
      @security_code = args[:security_code]
      @document_situation = args[:document_situation]
      @references = args[:references]
      @namespaces = {
        "xmlns:xsi"=>"http://www.w3.org/2001/XMLSchema-instance", 
        "xmlns:xsd"=>"http://www.w3.org/2001/XMLSchema",
        "xmlns"=>"https://tribunet.hacienda.go.cr/docs/esquemas/2017/v4.2/notaDebitoElectronica"
      }
    end
    
    def document_tag
      "NotaDebitoElectronica"
    end
    
  end 
end