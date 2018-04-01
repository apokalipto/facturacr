require "facturacr/document"
require 'facturacr/document/phone_type'
require 'active_model'
require 'nokogiri'

module FE
  class Document
    class Fax < PhoneType
      include ActiveModel::Validations
      
      attr_accessor :country_code, :number
      
      validates :country_code, presence: true, length: { maximum: 3 }
      validates :number, presence: true, length: {maximum: 20}
      
      
      def initialize(args={})
        super('Fax', args[:country_code], args[:number])
      end
      
    end
    
  end
end