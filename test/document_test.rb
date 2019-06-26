require_relative 'test_helper'

class DocumentTest < Minitest::Test
  def setup
    FE.configure do |config|
      config.version = "4.2"
    end
  end

  def test_invoice_xml_validation
    id_document = FE::Document::IdentificationDocument.new type: "01", number: "112345678"
    phone = FE::Document::Phone.new country_code: "506", number: "22222222"
    location = FE::Document::Location.new province: "1",county: "01", district: "01", others: "Otras señas"
    issuer = FE::Document::Issuer.new name: "EMISON EJEMPLO", identification_document: id_document, location: location, phone: phone, email: "emisor@ejemplo.com"

    reciever_id_document = FE::Document::IdentificationDocument.new type: "02", number: "3102123456"
    receiver = FE::Document::Receiver.new name: "RECEPTOR EJEMPLO", identification_document: id_document

    items = []
    #TODO exo = FE::Document::Exoneration.new(document_type: "05", document_number: "")
    items << FE::Document::Item.new(comercial_code: "001", line_number: 1, quantity: 1, unit: "Sp", description: "Desarrollo de Software y Mantenimiento", unit_price: 100, subtotal: 100, net_total: 100, total: 100, document_type: FE::Invoice::DOCUMENT_TYPE)
    taxes = [FE::Document::Tax.new(code: "01", rate: 13, total: (100 * 0.13))]
    items << FE::Document::Item.new(comercial_code: "002", line_number: 2, quantity: 2, unit: "Unid", description: "Impresora de POS", unit_price: 50, total: 100, taxes: taxes, net_total: 113, subtotal: 100, document_type: FE::Ticket::DOCUMENT_TYPE)
    summary = FE::Document::Summary.new currency: "USD", exchange_rate: 575, services_exent_total: 100, goods_taxable_total: 100, exent_total: 100, taxable_total: 100, subtotal: 200, gross_total: 200, tax_total: 13, net_total: 213, document_type: FE::Invoice::DOCUMENT_TYPE

    others = [FE::Document::OtherText.new(xml_attributes: {"code"=>"my123456"}, content: "This is the custom value")]

    payment =["01","03"]
    invoice = FE::Invoice.new date: Time.now, issuer: issuer, receiver: receiver, number: 1, items: items, condition: "01", summary: summary, security_code: "12345678", document_situation: "1", others: others,payment_type: payment, version: FE.configuration.version
    
    begin
      xml = invoice.generate
    rescue => e
      puts e.message
      ap e.messages if e.respond_to?(:messages)
      raise "ERROR"
    end
  
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
    items << FE::Document::Item.new(comercial_code: "001", line_number: 1, quantity: 1, unit: "Sp", description: "Desarrollo de Software y Mantenimiento", unit_price: 100, subtotal: 100, net_total: 100, total: 100, document_type: FE::Ticket::DOCUMENT_TYPE)
    taxes = [FE::Document::Tax.new(code: "01", rate: 13, total: (100 * 0.13))]
    items << FE::Document::Item.new(comercial_code: "002", line_number: 2, quantity: 2, unit: "Unid", description: "Impresora de POS", unit_price: 50, total: 100, taxes: taxes, net_total: 113, subtotal: 100, document_type: FE::Ticket::DOCUMENT_TYPE)
    summary = FE::Document::Summary.new currency: "USD", exchange_rate: 575, services_exent_total: 100, goods_taxable_total: 100, exent_total: 100, taxable_total: 100, subtotal: 200, gross_total: 200, tax_total: 13, net_total: 213, document_type: FE::Ticket::DOCUMENT_TYPE

    others = [FE::Document::OtherText.new(xml_attributes: {"code"=>"my123456"}, content: "This is the custom value")]

    payment =["01","03"]
    invoice = FE::Ticket.new date: Time.now, issuer: issuer, receiver: receiver, number: 1, items: items, condition: "01", summary: summary, security_code: "12345678", document_situation: "1", others: others, payment_type: payment, version: FE.configuration.version
    
    begin
      xml = invoice.generate
    rescue => e
      puts "#{e.message}"
      raise "ERROR"
    end
    
  end

  def test_document_can_set_key_manually
    invoice = FE::Invoice.new
    invoice.key = "MANUALINVALIDKEY"
    assert_equal invoice.key, "MANUALINVALIDKEY"
  end
  
  def test_identification_document
    long_name = "abcd" * 20
    id_document = FE::Document::IdentificationDocument.new type: "01", number: "112345678"
    phone = FE::Document::Phone.new country_code: "506", number: "22222222"
    location = FE::Document::Location.new province: "1",county: "01", district: "01", others: "Otras señas"
    issuer = FE::Document::Issuer.new name: "#{long_name} MAX", identification_document: id_document, location: location, phone: phone, email: "emisor@ejemplo.com"
    
    exception = assert_raises(FE::Error){issuer.build_xml(nil, FE::Invoice.new(version: "4.2"))}
  end


end
