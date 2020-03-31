require 'test_helper'

class FETest < Minitest::Test
    
  def get_invoice
    id_document = build_id_document("02", "3102111111")

    location = build_location("1","15","02", "Del palo de mango 100N 200E.")

    phone = build_phone("22222222")
    fax = build_fax("22222223")

    issuer = build_issuer("EMISOR EJEMPLO", id_document,location,"test@email.com",phone,fax)

    receiver_id_document = build_id_document("01", "111111111")
    receiver = build_receiver("Receptor Ejemplo",receiver_id_document)

    items = []
    items << FE::Document::Item.new(code: "001", line_number: 1, quantity: 1, unit: "Sp", description: "Desarrollo de Software y Mantenimiento", unit_price: 300, subtotal: 300, net_total: 300, total: 300, comercial_code: "001", document_type: "01")
    taxes = [FE::Document::Tax.new(code: "01", rate: 13, total: (100 * 0.13),rate_code: "08")]
    items << FE::Document::Item.new(code: "002", line_number: 2, quantity: 2, unit: "Unid", description: "Impresora de POS", unit_price: 50, total: 100, taxes: taxes, net_total: 113, subtotal: 100, comercial_code: "002", document_type: "01")
    summary = FE::Document::Summary.new currency: "USD", exchange_rate: 575, services_exent_total: 300, goods_taxable_total: 100, exent_total: 300, taxable_total: 100, subtotal: 400, gross_total: 400, tax_total: 13, net_total: 413
    invoice = build_invoice(1, Time.now, issuer, receiver,items,summary,"02",5)
    
    invoice
  end
    

  def test_that_it_has_a_version_number
    refute_nil ::FE::VERSION
  end
  
  

  def test_it_builds_a_valid_invoice_xml
    invoice = get_invoice
    result = invoice.valid?
    ap invoice.errors.messages if invoice.errors.messages.any?
    assert result
    assert invoice.generate
  end
  
  def test_it_builds_a_valid_credit_note_xml
    invoice = get_invoice
    credit_note = build_credit_note(1,invoice)
    result = credit_note.valid?
    ap credit_note.errors.messages if credit_note.errors.messages.any?
    assert credit_note.generate
  end
  
  def test_item
    taxes = [FE::Document::Tax.new(code: "01", rate: 13, total: (100 * 0.13), rate_code: "08")]
    item = FE::Document::Item.new(code: "002", line_number: 2, quantity: 2, unit: "Unid", description: "Impresora de POS", unit_price: 50, total: 100, taxes: taxes, net_total: 113, subtotal: 100, comercial_code: "001", document_type: "01")
    result = item.valid?
    ap item.errors.messages if item.errors.messages.any?
    assert result
  end
  
  
end
