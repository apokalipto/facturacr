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
    receiver = FE::Document::Receiver.new name: "RECEPTOR EJEMPLO", identification_document: id_document

    items = []
    exo = FE::Document::Exoneration.new(document_type: "01", document_number: "3737",institution:"Escuela San Roque",date: Time.now,total_tax: 34)

    items << FE::Document::Item.new(comercial_code: "001", line_number: 1, quantity: 1, unit: "Sp", description: "Desarrollo de Software y Mantenimiento", unit_price: 100, subtotal: 100, net_total: 100, total: 100,discount:10,discount_reason: "promocion")
    taxes = [FE::Document::Tax.new(code: "01",rate_code: "01", rate: 13, total: (100 * 0.13))]


    items << FE::Document::Item.new(comercial_code: "002", line_number: 2,tariff_item: 303, quantity: 2, unit: "Unid", description: "Impresora de POS", unit_price: 50, total: 100, taxes: taxes, net_total: 113, subtotal: 100, net_tax: 90)

    other_c= FE::Document::OtherCharges.new document_type: "01", detail:"Otro cargo", total_charge: 200
    summary = FE::Document::Summary.new currency: "USD", exchange_rate: 575, services_exent_total: 100 , services_exonerate_total: 100, goods_taxable_total: 100, goods_exonerate_total: 100, exent_total: 100, taxable_total: 100,exonerate_total: 200, subtotal: 200, gross_total: 200, tax_total: 13, net_total: 213

    others = [FE::Document::OtherText.new(xml_attributes: {"code"=>"my123456"}, content: "This is the custom value")]

  #  payment =["01","03"]
    invoice = FE::Invoice.new economic_activity: "01",date: Time.now, issuer: issuer, receiver: receiver, number: 1, items: items, condition: "01", summary: summary, other_charges: other_c , security_code: "12345678", document_situation: "1", others: others#, #payment_type: payment


  #xml=invoice.generate
  #ap xml=invoice.generate
  #    File.open("f⁩ile⁩.xml","w"){|f| f.write(xml)}
  end

  def test_ticket_xml_validation
    id_document = FE::Document::IdentificationDocument.new type: "01", number: "112345678"
    phone = FE::Document::Phone.new country_code: "506", number: "22222222"
    location = FE::Document::Location.new province: "1",county: "01", district: "01", others: "Otras señas"
    issuer = FE::Document::Issuer.new name: "EMISON EJEMPLO", identification_document: id_document, location: location, phone: phone, email: "emisor@ejemplo.com"

    reciever_id_document = FE::Document::IdentificationDocument.new type: "02", number: "3102123456"
    receiver = FE::Document::Receiver.new name: "RECEPTOR EJEMPLO", identification_document: id_document

    items = []
    #TODO exo = FE::Document::Exoneration.new(document_type: "05", document_number: "")
    items << FE::Document::Item.new(comercial_code: "001", line_number: 1, quantity: 1, unit: "Sp", description: "Desarrollo de Software y Mantenimiento", unit_price: 100, subtotal: 100, net_total: 100, total: 100)
    taxes = [FE::Document::Tax.new(code: "01",rate_code: "01", rate: 13, total: (100 * 0.13))]
    items << FE::Document::Item.new(comercial_code: "002", line_number: 2, quantity: 2, unit: "Unid", description: "Impresora de POS", unit_price: 50, total: 100, taxes: taxes, net_total: 113, subtotal: 100)
    other_c= FE::Document::OtherCharges.new document_type: "01", detail:"Otro cargo", total_charge: 200
    summary = FE::Document::Summary.new currency: "USD", exchange_rate: 575, services_exent_total: 100, goods_taxable_total: 100, exent_total: 100, taxable_total: 100, subtotal: 200, gross_total: 200, tax_total: 13, net_total: 213

    others = [FE::Document::OtherText.new(xml_attributes: {"code"=>"my123456"}, content: "This is the custom value")]
    payment =["01","03"]
    invoice = FE::Ticket.new  economic_activity: "01", date: Time.now, issuer: issuer, receiver: receiver, number: 1, items: items, condition: "01", summary: summary,other_charges: other_c , security_code: "12345678", document_situation: "1", others: others,payment_type:payment

    #xml=invoice.generate
    #ap xml=invoice.generate
    #File.open("ticket_file⁩.xml","w"){|f| f.write(xml)}

  end

  def test_export_invoice_xml_validation
    id_document = FE::Document::IdentificationDocument.new type: "01", number: "112345678"
    phone = FE::Document::Phone.new country_code: "506", number: "22222222"
    location = FE::Document::Location.new province: "1",county: "01", district: "01", others: "Otras señas"
    issuer = FE::Document::Issuer.new name: "EMISON EJEMPLO", identification_document: id_document, location: location, phone: phone, email: "emisor@ejemplo.com"

    reciever_id_document = FE::Document::IdentificationDocument.new type: "02", number: "3102123456"
    receiver = FE::Document::Receiver.new name: "RECEPTOR EJEMPLO", identification_document: id_document

    items = []
    #TODO exo = FE::Document::Exoneration.new(document_type: "05", document_number: "")
    items << FE::Document::Item.new(comercial_code: "001", line_number: 1, quantity: 1, unit: "Sp", description: "Desarrollo de Software y Mantenimiento", unit_price: 100, subtotal: 100, net_total: 100, total: 100)
    taxes = [FE::Document::Tax.new(code: "01",rate_code: "01", rate: 13, total: (100 * 0.13))]
    items << FE::Document::Item.new(comercial_code: "002", line_number: 2, quantity: 2, unit: "Unid", description: "Impresora de POS", unit_price: 50, total: 100, taxes: taxes, net_total: 113, subtotal: 100)
    other_c= FE::Document::OtherCharges.new document_type: "01", detail:"Otro cargo", total_charge: 200
    summary = FE::Document::Summary.new currency: "USD", exchange_rate: 575, services_exent_total: 100, goods_taxable_total: 100, exent_total: 100, taxable_total: 100, subtotal: 200, gross_total: 200, tax_total: 13, net_total: 213

    others = [FE::Document::OtherText.new(xml_attributes: {"code"=>"my123456"}, content: "This is the custom value")]
    payment =["01","03"]
    invoice = FE::Export_Invoice.new  economic_activity: "01", date: Time.now, issuer: issuer, receiver: receiver, number: 1, items: items, condition: "01", summary: summary,other_charges: other_c , security_code: "12345678", document_situation: "1", others: others, payment_type: payment


      xml=invoice.generate
    ap xml=invoice.generate
    File.open("ticket_file⁩.xml","w"){|f| f.write(xml)}

  end


  def test_document_can_set_key_manually
    invoice = FE::Invoice.new
    invoice.key = "MANUALINVALIDKEY"
    assert_equal invoice.key, "MANUALINVALIDKEY"
  end


end
