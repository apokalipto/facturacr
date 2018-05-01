$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'facturacr'

require 'facturacr/document'
require 'facturacr/document/fax'
require 'facturacr/document/identification_document'
require 'facturacr/document/issuer'
require 'facturacr/document/receiver'
require 'facturacr/document/location'
require 'facturacr/document/phone_type'
require 'facturacr/document/phone'
require 'facturacr/document/item'
require 'facturacr/document/tax'
require 'facturacr/document/summary'
require 'facturacr/document/regulation'
require 'facturacr/document/reference'

require 'facturacr/invoice'
require 'facturacr/credit_note'
require 'facturacr/signer/signer'
require 'facturacr/api'
require 'facturacr/signed_document'

require 'minitest/autorun'
require 'yaml'

class Minitest::Test
  def build_id_document(type,number)
    FE::Document::IdentificationDocument.new type: type, number: number
  end
  
  def build_location(province,county,district,others="")
    FE::Document::Location.new province: province,county: county, district: district, others: others
  end
  
  def build_phone(number)
    FE::Document::Phone.new country_code: "506", number: "22222222"
  end
  
  def build_fax(number)
    FE::Document::Fax.new country_code: "506", number: "22222222"
  end
  
  def build_issuer(name, id_document,location,email,phone=nil,fax=nil)
    FE::Document::Issuer.new name: name, identification_document: id_document, location: location, phone: phone, fax: fax, email: email
  end
  
  def build_receiver(name,id_document=nil,location=nil, phone=nil,fax=nil, email=nil)
    FE::Document::Receiver.new name: "RECEPTOR EJEMPLO", identification_document: id_document, location: location, phone: phone, fax: fax, email: email
  end
  
  def build_invoice(number,date,issuer,receiver,items,summary,condition="01",credit_term=nil)
    FE::Invoice.new date: date, issuer: issuer, receiver: receiver, number: number, items: items, condition: condition, credit_term: credit_term, summary: summary, security_code: "99999999", document_situation: "1"
  end
  
  def read_static_data
    if File.exists?("tmp/data.yml")
      data = YAML.load_file("tmp/data.yml")
      return data
    else
      raise "static data file (tmp/data.yml) does not exist."
    end
  end
  
  def build_credit_note(number, invoice)
    credit_note = FE::CreditNote.new
    credit_note.date = Time.now
    credit_note.issuer = invoice.issuer
    credit_note.receiver = invoice.receiver
    credit_note.number = number
    credit_note.items = invoice.items
    credit_note.condition = invoice.condition
    credit_note.security_code = "87305749"
    credit_note.document_situation = "1"
    credit_note.summary = invoice.summary
    credit_note.references = [FE::Document::Reference.new(document_type: invoice.document_type, number: invoice.key, date: invoice.date, code: "01", reason: "Anula documento")]
    credit_note.credit_term = "15"
    
    credit_note
  end
  
end