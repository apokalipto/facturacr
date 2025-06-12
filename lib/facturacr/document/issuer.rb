module FE
  class Document


      class Issuer < Element
        include ActiveModel::Validations

        attr_accessor :name, :identification_document, :comercial_name, :location, :phone, :fax, :email, :fiscal_registry_8707

        validates :name, presence: true
        validates :identification_document, presence: true
        validates :location, presence: true, if: -> {!document.document_type.eql?(FE::Payment::DOCUMENT_TYPE)}
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
          @fiscal_registry_8707 = args[:fiscal_registry_8707]
        end

        def build_xml(node, document)
          @document = document
          raise FE::Error.new("issuer invalid",class: self.class, messages: errors.messages) unless valid?

          node = Nokogiri::XML::Builder.new if node.nil?
          node.Emisor do |xml|
            xml.Nombre @name
            identification_document.build_xml(xml,document)
            xml.NombreComercial @comercial_name if @comercial_name
            xml.Registrofiscal8707 @fiscal_registry_8707 if @fiscal_registry_8707
            location.build_xml(xml, document) if @location.present?
            phone.build_xml(xml, document) if phone.present?
            fax.build_xml(xml, document) if fax.present?
            if document.version_42? || document.version_43?
              xml.CorreoElectronico @email
            elsif document.version_44?
              @email = [@email] if !@email.is_a?(Array)
              @email.each do |e|
                xml.CorreoElectronico e
              end
            end
          end
        end

        def to_xml(builder,document)
          build_xml(builder,document).to_xml
        end
      end

  end
end
