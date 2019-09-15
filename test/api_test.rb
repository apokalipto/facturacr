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
  
  def test_invoice
    data = read_static_data  
    builder = FE::Builder.new 
    invoice = builder.invoice(data[:document])
    ap invoice.items
    invoice.date = Time.now
    invoice.terminal = "00004"
    File.open('tmp/invoice.xml', 'w'){|f| f.write(invoice.generate)}
    
    data_provider = FE::DataProvider.new :string, invoice.generate
    key_provider = FE::DataProvider.new :string, File.read(FE.configuration.key_path)
    signer = FE::Signer.new xml_provider: data_provider, key_provider: key_provider, pin: FE.configuration.key_password, output_path: "tmp/out.xml"
    signer.sign
    
    signed_document = FE::SignedDocument.new(invoice,"tmp/out.xml")
    api = FE::Api.new
    puts "\nINVOICE\n".green
    h = signed_document.payload.dup
    xml = h.delete(:comprobanteXml)
    ap h
    api_send_result =  api.send_document(signed_document.payload)
    if api_send_result == false
      ap api_send_result.errors
    end
    assert api_send_result
    sleep 5
    
    document_status = api.get_document_status(signed_document.document.key)
    File.open('tmp/response.xml', 'w'){|f| f.write(document_status.xml)}
    ap document_status.to_h
    
    assert_equal "aceptado", document_status.status
    assert_equal signed_document.document.key, document_status.key       
  end
  
  
end