require_relative 'test_helper'

class Version43DocumentTest < Minitest::Test
  def setup
    FE.configure do |config|
      config.version = "4.3"
    end
  end
  
  def test_invoice_xml_validation
    id_document = FE::Document::IdentificationDocument.new type: "01", number: "112345678"
    phone = FE::Document::Phone.new country_code: "506", number: "22222222" 
    location = FE::Document::Location.new province: "1",county: "01", district: "01", others: "Otras señas"
    issuer = FE::Document::Issuer.new name: "EMISON EJEMPLO", identification_document: id_document, location: location, phone: phone, email: "emisor@ejemplo.com"
    
    reciever_id_document = FE::Document::IdentificationDocument.new type: "02", number: "3102123456"
    #receiver = FE::Document::Receiver.new name: "RECEPTOR EJEMPLO", identification_document: id_document
    receiver = nil
    items = []
    #TODO exo = FE::Document::Exoneration.new(document_type: "05", document_number: "")
    items << FE::Document::Item.new(code: "001", line_number: 1, quantity: 1, unit: "Sp", description: "Desarrollo de Software y Mantenimiento", unit_price: 100, subtotal: 100, net_total: 100, total: 100)
    taxes = [FE::Document::Tax.new(code: "01", rate: 13, total: (100 * 0.13))]
    items << FE::Document::Item.new(code: "002", line_number: 2, quantity: 2, unit: "Unid", description: "Impresora de POS", unit_price: 50, total: 100, taxes: taxes, net_total: 113, subtotal: 100)
    summary = FE::Document::Summary.new currency: "USD", exchange_rate: 575, services_exent_total: 100, goods_taxable_total: 100, exent_total: 100, taxable_total: 100, subtotal: 200, gross_total: 200, tax_total: 13, net_total: 213
    
    others = [FE::Document::OtherText.new(xml_attributes: {"code"=>"my123456"}, content: "This is the custom value")]
     
    invoice = FE::Invoice.new date: Time.now, issuer: issuer, receiver: receiver, number: 1, items: items, condition: "01", summary: summary, security_code: "12345678", document_situation: "1", others: others

    invoice.generate
  end
  
  def test_ticket_xml_validation
    id_document = FE::Document::IdentificationDocument.new type: "01", number: "112345678"
    phone = FE::Document::Phone.new country_code: "506", number: "22222222" 
    location = FE::Document::Location.new province: "1",county: "01", district: "01", others: "Otras señas"
    issuer = FE::Document::Issuer.new name: "EMISON EJEMPLO", identification_document: id_document, location: location, phone: phone, email: "emisor@ejemplo.com"
    
    reciever_id_document = FE::Document::IdentificationDocument.new type: "02", number: "3102123456"
    #receiver = FE::Document::Receiver.new name: "RECEPTOR EJEMPLO", identification_document: id_document
    receiver = nil
    items = []
    #TODO exo = FE::Document::Exoneration.new(document_type: "05", document_number: "")
    items << FE::Document::Item.new(code: "001", line_number: 1, quantity: 1, unit: "Sp", description: "Desarrollo de Software y Mantenimiento", unit_price: 100, subtotal: 100, net_total: 100, total: 100)
    taxes = [FE::Document::Tax.new(code: "01", rate: 13, total: (100 * 0.13))]
    items << FE::Document::Item.new(code: "002", line_number: 2, quantity: 2, unit: "Unid", description: "Impresora de POS", unit_price: 50, total: 100, taxes: taxes, net_total: 113, subtotal: 100)
    summary = FE::Document::Summary.new currency: "USD", exchange_rate: 575, services_exent_total: 100, goods_taxable_total: 100, exent_total: 100, taxable_total: 100, subtotal: 200, gross_total: 200, tax_total: 13, net_total: 213
    
    others = [FE::Document::OtherText.new(xml_attributes: {"code"=>"my123456"}, content: "This is the custom value")]
     
    invoice = FE::Ticket.new date: Time.now, issuer: issuer, receiver: receiver, number: 1, items: items, condition: "01", summary: summary, security_code: "12345678", document_situation: "1", others: others

    invoice.generate
  end
  
  def test_document_can_set_key_manually
    invoice = FE::Invoice.new
    invoice.key = "MANUALINVALIDKEY"
    assert_equal invoice.key, "MANUALINVALIDKEY"
  end
  
  
end