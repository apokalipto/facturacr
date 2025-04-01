module FE
  class Document


      class Location < Element
        include ActiveModel::Validations

        attr_accessor :province, :county,:district,:neighborhood, :others,:other_foreign_signs

        validates :province, presence: true, length: { is: 1 }
        validates :county, presence: true, length: { is: 2 }
        validates :district, presence: true, length: { is: 2 }
        validates :neighborhood, length: { is: 2 }, allow_blank: true, if: -> {document.version_42? || document.version_43?}
        validates :neighborhood, length: { maximum: 50 }, allow_blank: true, if: -> {document.version_44?}
        validates :others, presence: true, length: { maximum: 250 }

        def initialize(args={})

          @province = args[:province]
          @county = args[:county]
          @district = args[:district]
          @neighborhood = args[:neighborhood]
          @others = args[:others]
          @other_foreign_signs = args[:other_foreign_signs]


        end

        def build_xml(node, document)
          raise FE::Error.new("location invalid",class: self.class, messages: errors.messages) unless valid?
          node = Nokogiri::XML::Builder.new if node.nil?
          node.Ubicacion do |x|
            x.Provincia @province
            x.Canton @county
            x.Distrito @district
            x.Barrio @neighborhood unless @neighborhood.nil?
            x.OtrasSenas @others
            x.OtrasSenasExtranjero @other_foreign_signs if document.version_44?
          end
        end

        def to_xml(builder,document)
          build_xml(builder,document).to_xml
        end

      end
  end
end
