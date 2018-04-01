require "facturacr/document"
require 'active_model'
require 'nokogiri'

module FE
  class Document
    class PhoneType
      include ActiveModel::Validations
      
      attr_accessor :tag_name, :country_code, :number
      
      validates :tag_name, presence: true, inclusion: ['Telefono','Fax']
      validates :country_code, presence: true, length: { maximum: 3 }
      validates :number, presence: true, length: {maximum: 20}, format: {with: /\d+/}
      
      
      def initialize(tag_name, country_code, number)
        @tag_name = tag_name
        @country_code = country_code
        @number = number
      end
      
      def build_xml(node)
        raise "Invalid Record: #{errors.messages}" unless valid?
        node = Nokogiri::XML::Builder.new if node.nil?         
        node.send(tag_name) do |xml|
          xml.CodigoPais country_code
          xml.NumTelefono number
        end
      end
      
      def to_xml(builder)
        build_xml(builder).to_xml
      end
    end
  end
end