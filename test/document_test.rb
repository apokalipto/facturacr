require_relative 'test_helper'

class DocumentTest < Minitest::Test
  
  def test_invoice_xml_validation
    id_document = FE::Document::IdentificationDocument.new type: "01", number: "112345678"
    phone = FE::Document::Phone.new country_code: "506", "22222222" 
    location = FE::Document::Location.new province: "1",county: "01", district: "01", others: "Otras señas"
    issuer = FE::Document::Issuer.new name: "EMISON EJEMPLO", identification_document: id_document, location: location, phone: phone, email: "emisor@ejemplo.com"
    
    reciever_id_document = FE::Document::IdentificationDocument.new type: "02", number: "3102123456"
    receiver = FE::Document::Receiver.new name: "RECEPTOR EJEMPLO", identification_document: id_document
    
    items = []
    items << FE::Document::Item.new(code: "001", line_number: 1, quantity: 1, unit: "Sp", description: "Desarrollo de Software y Mantenimiento", unit_price: 100, subtotal: 100, net_total: 100, total: 100)
    taxes = [FE::Document::Tax.new(code: "01", rate: 13, total: (100 * 0.13))]
    items << FE::Document::Item.new(code: "002", line_number: 2, quantity: 2, unit: "Unid", description: "Impresora de POS", unit_price: 50, total: 100, taxes: taxes, net_total: 113, subtotal: 100)
    summary = FE::Document::Summary.new currency: "USD", exchange_rate: 575, services_exent_total: 100, goods_taxable_total: 100, exent_total: 100, taxable_total: 100, subtotal: 200, gross_total: 200, tax_total: 13, net_total: 213
        
    invoice = FE::Invoice.new date: date, issuer: issuer, receiver: receiver, number: number, items: items, condition: condition, credit_term: credit_term, summary: summary, security_code: "12345678", document_situation: "1"
    
    # Para generar el XML
    invoice.generate
  end
end