require 'active_model'
require 'nokogiri'

module FE
  class Document


      class Receiver < Element
        include ActiveModel::Validations

        attr_accessor :name, :identification_document,:foreign_id_number, :comercial_name, :location, :phone, :fax, :email,:other_foreign_signs, :document_type

        validates :name, presence: true

        validates :identification_document, presence: true, if: -> {document_type.eql?("01") || document_type.eql?("08")}
        validates :foreign_id_number, length: { maximum: 20 }, if: -> {document_type.eql?("01") || document_type.eql?("08")}
        validates :other_foreign_signs,length: { maximum: 300 }
        validates :email, length: {maximum: 160}, format:{with: /\s*\w+([-+.']\w+)*@\w+([-.]\w+)*\.\w+([-.]\w+)*\s*/}, if: ->{ email.present? }


        validates :name, length: { maximum: 80}, if: ->{ document.version_42? }
        validates :comercial_name, length: { maximum: 80 }, if: ->{ document.version_42? }


        validates :name, length: { maximum: 100}, if: ->{ document.version_43? }
        validates :comercial_name, length: { maximum: 100 }, if: ->{ document.version_43? }


        def initialize(args={})

          @name = args[:name]
          @identification_document = args[:identification_document]
          @comercial_name = args[:comercial_name]
          @location = args[:location]
          @phone = args[:phone]
          @fax = args[:fax]
          @email = args[:email]
          @foreign_id_number = args[:foreign_id_number]
          @other_foreign_signs= args[:other_foreign_signs]

        end

        def build_xml(node, document)
          @document = document
          @document_type = document.document_type
          raise FE::Error.new("receiver invalid",class: self.class, messages: errors.messages) unless valid?

          node = Nokogiri::XML::Builder.new if node.nil?
          node.Receptor do |xml|
            xml.Nombre @name
            @identification_document.build_xml(xml,@document) if @identification_document.present?
            xml.IdentificacionExtranjero foreign_id_number if @foreign_id_number.present? && @document.version_43?
            xml.NombreComercial @comercial_name if @comercial_name.present?
            @location.build_xml(xml,@document) if @location.present?
            @phone.build_xml(xml, @document) if @phone.present?
            @fax.build_xml(xml, @document) if @fax.present?
            xml.CorreoElectronico @email if @email.present?
            xml.OtrasSenasExtranjero @other_foreign_signs if @other_foreign_signs.present? &&  @document.version_43?
          end
        end

        def to_xml(builder, document)
          build_xml(builder, document).to_xml
        end
      end

  end
end
