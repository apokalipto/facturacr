require_relative 'test_helper'
require 'open3'
class SignerTest < Minitest::Test

  def test_ruby_signer_produces_valid_signature
    
    data_provider = FE::DataProvider.new 'file', 'resources/invoice.xml'
    key_provider = FE::DataProvider.new 'file', 'resources/test.p12'
    
    signer = FE::Signer.new({xml_provider: data_provider, key_provider: key_provider, pin: 'test', output_path: 'tmp/ruby_signer_out.xml'})
    signer.sign
    stderr = Open3.capture3("xmlsec1 --verify tmp/ruby_signer_out.xml")[1]
    puts
    puts "xmlsec1 --verify tmp/ruby_signer_out.xml"
    puts stderr
    puts 
    assert stderr =~ /\nOK\n/
    assert stderr =~ /SignedInfo References \(ok\/all\): 3\/3/
  end

  def test_java_signer_produces_valid_signature
    signer = FE::JavaSigner.new('resources/test.p12','test','resources/invoice.xml','tmp/java_signer_out.xml')
    signer.sign
    stderr = Open3.capture3("xmlsec1 --verify tmp/java_signer_out.xml")[1]
    puts
    puts "xmlsec1 --verify tmp/java_signer_out.xml"
    puts stderr
    puts 
    assert stderr =~ /\nOK\n/
    assert stderr =~ /SignedInfo References \(ok\/all\): 3\/3/
  end
  
  def test_inmemory_signer
    
    data_provider = FE::DataProvider.new 'string', File.read('resources/invoice.xml')
    key_provider = FE::DataProvider.new 'string', File.read('resources/test.p12')
    
    signer = FE::Signer.new({xml_provider: data_provider, key_provider: key_provider, pin: 'test', output_path: 'tmp/memory_signer_out.xml'})
    
    signer.sign
    stderr = Open3.capture3("xmlsec1 --verify tmp/memory_signer_out.xml")[1]
    puts
    puts "xmlsec1 --verify tmp/memory_signer_out.xml"
    puts stderr
    puts 
    assert stderr =~ /\nOK\n/
    assert stderr =~ /SignedInfo References \(ok\/all\): 3\/3/
  end
  
  def test_sign_generated_document
    data = read_static_data  
    builder = FE::Builder.new 
    invoice = builder.invoice(data[:document])
    invoice.date = Time.now
    xml = invoice.generate
    File.open('tmp/ruby-generated-document.xml', 'w'){ |f| f.write(xml) }
    
    data_provider = FE::DataProvider.new 'string', xml
    key_provider = FE::DataProvider.new 'string', File.read('resources/test.p12')
    
    signer = FE::Signer.new({xml_provider: data_provider, key_provider: key_provider, pin: 'test', output_path: 'tmp/generated_memory_signer_out.xml'})
    
    signer.sign
    stderr = Open3.capture3("xmlsec1 --verify tmp/generated_memory_signer_out.xml")[1]
    puts
    puts "xmlsec1 --verify tmp/generated_memory_signer_out.xml"
    puts stderr
    puts 
    assert stderr =~ /\nOK\n/
    assert stderr =~ /SignedInfo References \(ok\/all\): 3\/3/
    
  end

end