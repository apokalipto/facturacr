require "active_support"
require "active_support/core_ext/time"
require "active_support/time"
require "active_support/core_ext/hash/conversions"
require_relative 'test_helper'

Time.zone = "Central America"

class Version44DocumentTest < Minitest::Test
  def setup
    FE.configure do |config|
      config.version = "4.4"
    end
  end

  def test_invoice_xml_validation
    id_document = FE::Document::IdentificationDocument.new type: "01", number: "112345678"
    phone = FE::Document::Phone.new country_code: "506", number: "22222222"
    location = FE::Document::Location.new province: "1",county: "01", district: "01", others: "Otras señas"
    issuer = FE::Document::Issuer.new name: "EMISON EJEMPLO", identification_document: id_document, location: location, phone: phone, email: "emisor@ejemplo.com"

    reciever_id_document = FE::Document::IdentificationDocument.new type: "02", number: "3102123456"

    receiver = FE::Document::Receiver.new name: "RECEPTOR EJEMPLO", identification_document: reciever_id_document

    items = []
    #TODO exo = FE::Document::Exoneration.new(document_type: "05", document_number: "")
    item = FE::Document::Item.new(code: "7331100000000",comercial_code: "001", line_number: 1, quantity: 1, unit: "Sp", description: "Desarrollo de Software y Mantenimiento", unit_price: 100, subtotal: 100, net_total: 100, total: 100, document_type: FE::Invoice::DOCUMENT_TYPE,transaction_type: "01")
    combo_item = FE::Document::Item.new(code: "7331100000000",comercial_code: "0011", line_number: 1, quantity: 1, unit: "Sp", description: "item 1", unit_price: 50, subtotal: 50, net_total: 50, total: 50, document_type: FE::Invoice::DOCUMENT_TYPE)
    combo_item_2 = FE::Document::Item.new(code: "7331100000000",comercial_code: "0011", line_number: 1, quantity: 1, unit: "Sp", description: "item 2", unit_price: 50, subtotal: 50, net_total: 50, total: 50, document_type: FE::Invoice::DOCUMENT_TYPE)
    item.combo_items = []
    item.combo_items << combo_item
    item.combo_items << combo_item_2
    items << item
    taxes = [FE::Document::Tax.new(code: "01", rate: 13, total: (100 * 0.13))]
    items << FE::Document::Item.new(code: "7331100000000",comercial_code: "002", line_number: 2, quantity: 2, unit: "Unid", description: "Impresora de POS", unit_price: 50, total: 100, taxes: taxes, net_total: 113, subtotal: 100, document_type: FE::Ticket::DOCUMENT_TYPE,transaction_type: "01")
    payment_method = FE::Document::PaymentMethod.new(payment_type: "01",amount: 213)
    payment_method_2 = FE::Document::PaymentMethod.new(payment_type: "02",amount: 213)
    summary = FE::Document::Summary.new currency: "USD", exchange_rate: 575, services_exent_total: 100, goods_taxable_total: 100, exent_total: 100, taxable_total: 100, subtotal: 200, gross_total: 200, tax_total: 13, net_total: 213, document_type: FE::Invoice::DOCUMENT_TYPE,payment_methods: [payment_method,payment_method_2]

    others = [FE::Document::OtherText.new(xml_attributes: {"code"=>"my123456"}, content: "This is the custom value")]

    # payment =["01","03"]
    invoice = FE::Invoice.new economic_activity: "01",receiver_economic_activity: "02", software_supplier: "3102123456", date: Time.now, issuer: issuer, receiver: receiver, number: 1, items: items, condition: "01", summary: summary, security_code: "12345678", document_situation: "1", others: others, version: "4.4"

    begin
      xml = invoice.generate
      doc = Nokogiri::XML(xml)
      document_hash = Hash.from_xml(doc.to_s)
      ap document_hash
      assert xml
    rescue => e
      puts e.message
      ap e.messages if e.respond_to?(:messages)
      ap e.backtrace
      raise "ERROR"
    end

  end
end
