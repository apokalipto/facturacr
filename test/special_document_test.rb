require_relative 'test_helper'

class SpecialDocumentTest < Minitest::Test


  def test_price_smart_purchase_document
    id_document = FE::Document::IdentificationDocument.new type: "01", number: "112345678"
    phone = FE::Document::Phone.new country_code: "506", number: "22222222" 
    location = FE::Document::Location.new province: "1",county: "01", district: "01", others: "Otras señas"
    issuer = FE::Document::Issuer.new name: "EMISON EJEMPLO", identification_document: id_document, location: location, phone: phone, email: "emisor@ejemplo.com"
  
    reciever_id_document = FE::Document::IdentificationDocument.new type: "02", number: "3102123456"
    receiver = FE::Document::Receiver.new name: "RECEPTOR EJEMPLO", identification_document: id_document
  
    items = []
    exo = FE::Document::Exoneration.new(document_type: "05", document_number: "")
    items << FE::Document::Item.new(code: "001", line_number: 1, quantity: 1, unit: "Sp", description: "Desarrollo de Software y Mantenimiento", unit_price: 100, subtotal: 100, net_total: 100, total: 100)
    taxes = [FE::Document::Tax.new(code: "01", rate: 13, total: (100 * 0.13))]
    items << FE::Document::Item.new(code: "002", line_number: 2, quantity: 2, unit: "Unid", description: "Impresora de POS", unit_price: 50, total: 100, taxes: taxes, net_total: 113, subtotal: 100)
    summary = FE::Document::Summary.new currency: "USD", exchange_rate: 575, services_exent_total: 100, goods_taxable_total: 100, exent_total: 100, taxable_total: 100, subtotal: 200, gross_total: 200, tax_total: 13, net_total: 213
  
    prices_smart_implementation = FE::Document::OtherContent::PriceSmart.new(transaction_type: 'purchase', supplier_number: "12345678910", order_number: "123456789",order_date: Time.now, store_code: "GLN0000")
    other_content = FE::Document::OtherContent.new(implementation: prices_smart_implementation)
    others = [other_content]
   
    invoice = FE::Invoice.new date: Time.now, issuer: issuer, receiver: receiver, number: 1, items: items, condition: "01", summary: summary, security_code: "12345678", document_situation: "1", others: others

    xml = invoice.generate
  
  end

  def test_price_smart_expense_document
    id_document = FE::Document::IdentificationDocument.new type: "01", number: "112345678"
    phone = FE::Document::Phone.new country_code: "506", number: "22222222" 
    location = FE::Document::Location.new province: "1",county: "01", district: "01", others: "Otras señas"
    issuer = FE::Document::Issuer.new name: "EMISON EJEMPLO", identification_document: id_document, location: location, phone: phone, email: "emisor@ejemplo.com"
  
    reciever_id_document = FE::Document::IdentificationDocument.new type: "02", number: "3102123456"
    receiver = FE::Document::Receiver.new name: "RECEPTOR EJEMPLO", identification_document: id_document
  
    items = []
    exo = FE::Document::Exoneration.new(document_type: "05", document_number: "")
    items << FE::Document::Item.new(code: "001", line_number: 1, quantity: 1, unit: "Sp", description: "Desarrollo de Software y Mantenimiento", unit_price: 100, subtotal: 100, net_total: 100, total: 100)
    taxes = [FE::Document::Tax.new(code: "01", rate: 13, total: (100 * 0.13))]
    items << FE::Document::Item.new(code: "002", line_number: 2, quantity: 2, unit: "Unid", description: "Impresora de POS", unit_price: 50, total: 100, taxes: taxes, net_total: 113, subtotal: 100)
    summary = FE::Document::Summary.new currency: "USD", exchange_rate: 575, services_exent_total: 100, goods_taxable_total: 100, exent_total: 100, taxable_total: 100, subtotal: 200, gross_total: 200, tax_total: 13, net_total: 213
  
    prices_smart_implementation = FE::Document::OtherContent::PriceSmart.new(transaction_type: 'expense', supplier_number: "12345678910", store_code: "GLN0000")
    other_content = FE::Document::OtherContent.new(implementation: prices_smart_implementation)
    others = [other_content]
   
    invoice = FE::Invoice.new date: Time.now, issuer: issuer, receiver: receiver, number: 1, items: items, condition: "01", summary: summary, security_code: "12345678", document_situation: "1", others: others

    xml = invoice.generate
  
  end
end