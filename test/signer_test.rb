require_relative 'test_helper'
require 'open3'
class SignerTest < Minitest::Test
  
  def test_ruby_signer_produces_valid_signature
    signer = FE::Signer.new('resources/test.p12','testtest','resources/invoice.xml','tmp/signer_out.xml')
    signer.sign
    stdout, stderr, status = Open3.capture3("xmlsec1 --verify tmp/signer_out.xml")
    puts
    puts "xmlsec1 --verify tmp/signer_out.xml"
    puts stderr
    puts 
    assert stderr =~ /\nOK\n/
    assert stderr =~ /SignedInfo References \(ok\/all\): 3\/3/
  end
  
  def test_java_signer_produces_valid_signature
    signer = FE::JavaSigner.new('resources/test.p12','testtest','resources/invoice.xml','tmp/signer_out.xml')
    signer.sign
    stdout, stderr, status = Open3.capture3("xmlsec1 --verify tmp/signer_out.xml")
    puts
    puts "xmlsec1 --verify tmp/signer_out.xml"
    puts stderr
    puts 
    assert stderr =~ /\nOK\n/
    assert stderr =~ /SignedInfo References \(ok\/all\): 3\/3/
  end
end