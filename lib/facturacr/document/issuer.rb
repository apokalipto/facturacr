module FE
  class Document


      class Issuer < Element
        include ActiveModel::Validations

        attr_accessor :name, :identification_document, :comercial_name, :location, :phone, :fax, :email

        validates :name, presence: true
        validates :identification_document, presence: true
        validates :location, presence: true
        validates :email, presence: true,length: {maximum: 160}, format:{with: /\s*\w+([-+.']\w+)*@\w+([-.]\w+)*\.\w+([-.]\w+)*\s*/}
        
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
        end

        def build_xml(node, document)
          @document = document
          raise FE::Error.new("issuer invalid",class: self.class, messages: errors.messages) unless valid?

          node = Nokogiri::XML::Builder.new if node.nil?
          node.Emisor do |xml|
            xml.Nombre @name
            identification_document.build_xml(xml,document)
            xml.NombreComercial @comercial_name if @comercial_name
            location.build_xml(xml, document)
            phone.build_xml(xml, document) if phone.present?
            fax.build_xml(xml, document) if fax.present?
            xml.CorreoElectronico @email
          end
        end

        def to_xml(builder,document)
          build_xml(builder,document).to_xml
        end
      end

  end
end
