module FE
  class Document


      class Location < Element
        include ActiveModel::Validations

        attr_accessor :province, :county,:district,:neighborhood, :others

        validates :province, presence: true, length: { is: 1 }
        validates :county, presence: true, length: { is: 2 }
        validates :district, presence: true, length: { is: 2 }
        validates :neighborhood, length: { is: 2 }, allow_blank: true
        validates :others, presence: true, length: { maximum: 250 }

        def initialize(args={})

          @province = args[:province]
          @county = args[:county]
          @district = args[:district]
          @neighborhood = args[:neighborhood]
          @others = args[:others]


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
          end
        end

        def to_xml(builder,document)
          build_xml(builder,document).to_xml
        end

      end
  end
end
