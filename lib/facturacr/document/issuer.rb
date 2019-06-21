require "facturacr/document"
require 'active_model'
require 'nokogiri'

module FE
  class Document


      class Issuer
        include ActiveModel::Validations

        attr_accessor :name, :identification_document, :comercial_name, :location, :phone, :fax, :email

        validates :name, presence: true, length: { maximum: 100 }
        validates :identification_document, presence: true
        validates :comercial_name, length: {maximum: 80}
        validates :location, presence: true
        validates :email, presence: true,length: {maximum: 160}, format:{with: /\s*\w+([-+.']\w+)*@\w+([-.]\w+)*\.\w+([-.]\w+)*\s*/}


        def initialize(args={})
          @name = args[:name]
          @identification_document = args[:identification_document]
          @comercial_name = args[:comercial_name]
          @location = args[:location]
          @phone = args[:phone]
          @fax = args[:fax]
          @email = args[:email]
        end

        def build_xml(node)
          raise FE::Error("identification document not present or invalid",class: self.class, messages: {identification_document: ["blank"]}) if @identification_document.nil? || !@identification_document.is_a?(IdentificationDocument)
          raise FE::Error("location not present or invalid",class: self.class, messages: {location: ["blank"]}) if @location.nil? || !@location.is_a?(Location)
          raise FE::Error("phone not present or invalid",class: self.class, messages: {phone: ["blank"]}) if !@phone.nil? && !@phone.is_a?(Phone)
          raise FE::Error("fax not present or invalid",class: self.class, messages: {fax: ["blank"]}) if !@fax.nil? && !@fax.is_a?(Fax)
          raise FE::Error("issuer invalid",class: self.class, messages: errors.messages) unless valid?

          node = Nokogiri::XML::Builder.new if node.nil?
          node.Emisor do |xml|
            xml.Nombre @name
            identification_document.build_xml(xml)
            xml.NombreComercial @comercial_name if @comercial_name
            location.build_xml(xml)
            phone.build_xml(xml) if phone.present?
            fax.build_xml(xml) if fax.present?
            xml.CorreoElectronico @email
          end
        end

        def to_xml(builder)
          build_xml(builder).to_xml
        end
      end

  end
end
