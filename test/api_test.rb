require_relative 'test_helper'

class ApiTest < Minitest::Test
  
  def invoice
    @@receiver_document_id ||= build_id_document("01","")
    @@invoice ||= build_invoice
  end
  
  def setup
    FE.configure do |config|
      config.mode = "file"
      config.file_path = "tmp/config.yml"
      config.environment = "test"
    end
  end
  
  def teardown
    FE.configuration = nil
    FE.configuration {}
  end
  
  
  def test_can_authenticate
    api = FE::Api.new
    token = api.authenticate
    assert_kind_of String,token
  end
  
  def test_cannot_authenticate
    api = FE::Api.new(FE::Configuration.new)
    assert_raises do
      api.authenticate
    end
  end
  
  def test_invoice_credit_note_cycle
    data = read_static_data  
    builder = FE::Builder.new 
    invoice = builder.invoice(data[:document])
    invoice.date = Time.now
    
    File.open('tmp/invoice.xml', 'w'){|f| f.write(invoice.generate)}
    
    data_provider = FE::DataProvider.new :string, invoice.generate
    key_provider = FE::DataProvider.new :string, File.read(FE.configuration.key_path)
    #signer = FE::JavaSigner.new FE.configuration.key_path, FE.configuration.key_password, "tmp/invoice.xml", "tmp/out.xml"
    signer = FE::Signer.new xml_provider: data_provider, key_provider: key_provider, pin: FE.configuration.key_password, output_path: "tmp/out.xml"
    signer.sign
    
    signed_document = FE::SignedDocument.new(invoice,"tmp/out.xml")
    api = FE::Api.new
    
    puts "\nINVOICE\n".green
    h = signed_document.payload.dup
    h.delete(:comprobanteXml)
    ap h
    assert api.send_document(signed_document.payload)
    sleep 5
    
    document_status = api.get_document_status(signed_document.document.key)
    assert_equal "aceptado", document_status.status
    assert_equal signed_document.document.key, document_status.key
    ap document_status.to_h
    
    
    credit_memo = FE::CreditNote.new
    credit_memo.date = Time.now
    credit_memo.issuer = issuer
    credit_memo.receiver = receiver
    credit_memo.number = data["credit_note"]["number"].to_i
    credit_memo.items = items
    credit_memo.condition = invoice.condition
    credit_memo.security_code = "99999999"
    credit_memo.document_situation = "1"
    credit_memo.summary = FE::Document::Summary.new currency: "USD", exchange_rate: 575, services_exent_total: 100, goods_taxable_total: 100, exent_total: 100, taxable_total: 100, subtotal: 200, gross_total: 200, tax_total: 13, net_total: 213
    credit_memo.references = [FE::Document::Reference.new(document_type: invoice.document_type, number: invoice.key, date: invoice.date, code: "01", reason: "Anula documento")]
    credit_memo.credit_term = "15"
    File.open('tmp/credit_note.xml', 'w'){|f| f.write(credit_memo.build_xml.to_xml)}

    signer = FE::JavaSigner.new FE.configuration.key_path, FE.configuration.key_password,"tmp/credit_note.xml", "tmp/cn_out.xml"
    signer.sign
    signed_document = FE::SignedDocument.new(credit_memo,"tmp/cn_out.xml")
    
    puts "\nCREDIT NOTE\n".green
    h = signed_document.payload.dup
    h.delete(:comprobanteXml)
    ap h
    assert api.send_document(signed_document.payload)
    sleep 5
    
    document_status = api.get_document_status(signed_document.document.key)
    ap document_status.to_h
    assert_equal "aceptado", document_status.status
    assert_equal signed_document.document.key, document_status.key
    
    
  end
  
end