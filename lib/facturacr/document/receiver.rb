require "facturacr/document"
require 'active_model'
require 'nokogiri'

module FE
  class Document
    
      
      class Receiver
        include ActiveModel::Validations
        
        attr_accessor :name, :identification_document,:foreign_id_number, :comercial_name, :location, :phone, :fax, :email
        
        validates :name, presence: true, length: { maximum: 80 }
        validates :comercial_name, length: { maximum: 80 }
        validates :foreign_id_number, length: { maximum: 20 }
        
        
        
        def initialize(args={})
          
          @name = args[:name]
          @identification_document = args[:identification_document]
          @comercial_name = args[:comercial_name]
          @location = args[:location]
          @phone = args[:phone]
          @fax = args[:fax]
          @email = args[:email]
          @foreign_id_number = args[:foreign_id_number]
          
        end
        
        def build_xml(node)
          raise "IdentificationDocument is invalid" if !@identification_document.nil? && !@identification_document.is_a?(IdentificationDocument)
          raise "Location is invalid" if !@location.nil? && !@location.is_a?(Location)
          raise "Phone is invalid" if !@phone.nil? && !@phone.is_a?(Phone)
          raise "Fax is invalid" if !@fax.nil? && !@fax.is_a?(Fax)
          raise "Reciever is invalid: #{errors.messages}" unless valid?
           
          node = Nokogiri::XML::Builder.new if node.nil?
          node.Receptor do |xml|
            xml.Nombre @name
            @identification_document.build_xml(xml) if @identification_document.present?
            xml.IdentificacionExtranjer foreign_id_number if @foreign_id_number.present?
            xml.NombreComercial @comercial_name if @comercial_name.present?
            @location.build_xml(xml) if @location.present?
            @phone.build_xml(xml) if @phone.present?
            @fax.build_xml(xml) if @fax.present?
            xml.CorreElectronico @email if @email.present?
          end          
        end
        
        def to_xml(builder)
          build_xml(builder).to_xml
        end
      end
    
  end
end