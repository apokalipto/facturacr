require_relative 'test_helper'

require 'benchmark'


  
def generate_document
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
      
  invoice = FE::Invoice.new date: Time.now, issuer: issuer, receiver: receiver, number: 1, items: items, condition: "01", summary: summary, security_code: "12345678", document_situation: "1"
  file_name = "tmp/#{SecureRandom.uuid}.xml"
  File.open(file_name, 'w'){|f| f.write(invoice.generate.gsub("\n",""))}
  return file_name
end

def java_signer
  signer = FE::JavaSigner.new('resources/test.p12','test',generate_document,"tmp/#{SecureRandom.uuid}.xml")
  signer.sign
end

def ruby_signer
  dp = FE::DataProvider.new 'file', 'tmp/rub-signer-invoice.xml'
  kp = FE::DataProvider.new 'file', 'resources/test.p12' 
  signer = FE::Signer.new({xml_provider: dp, key_provider: kp, pin: 'test', output_path: 'tmp/ruby_signer_out.xml'})
  signer.sign
end

def data_provider
  @data_provider ||= FE::DataProvider.new 'string', File.read('tmp/rub-signer-invoice.xml')
end

def key_provider
  @key_provider ||= FE::DataProvider.new 'string', File.read('resources/test.p12')
end

def memory_signer
  dp = data_provider
  kp = key_provider
  signer = FE::Signer.new({xml_provider: dp, key_provider: kp, pin: 'test', output_path: 'tmp/ruby_signer_out.xml'})
  signer.sign 
end

Benchmark.bm(10) do |x|
  x.report("ruby:"){ ruby_signer }
  x.report("java:"){ java_signer }
  x.report("memory:"){ memory_signer }
end

  