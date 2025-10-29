module FE
  class Document


      class Location < Element
        include ActiveModel::Validations

        attr_accessor :province, :county,:district,:neighborhood, :others

        validates :province, presence: true, length: { is: 1 }, if: -> {!document.document_type.eql?("08")}
        validates :county, presence: true, length: { is: 2 }, if: -> {!document.document_type.eql?("08")}
        validates :district, presence: true, length: { is: 2 }, if: -> {!document.document_type.eql?("08")}
        validates :neighborhood, length: { is: 2 }, allow_blank: true, if: -> {document.version_42? || document.version_43?}
        validates :neighborhood, length: { maximum: 50 }, allow_blank: true, if: -> {document.version_44? && !document.document_type.eql?("08")}
        validates :others, presence: true, length: { maximum: 250 }, if: -> {document.version_43?}
        validates :others, presence: true, length: { minimum: 5,maximum: 160 }, if: -> {document.version_44? && !document.document_type.eql?("08")}

        def initialize(args={})

          @province = args[:province]
          @county = args[:county]
          @district = args[:district]
          @neighborhood = args[:neighborhood]
          @others = args[:others]

        end

        def build_xml(node, document)
          @document = document
          raise FE::Error.new("location invalid",class: self.class, messages: errors.messages) unless valid?
          node = Nokogiri::XML::Builder.new if node.nil?
          node.Ubicacion do |x|
            x.Provincia @province if @province
            x.Canton @county if @county
            x.Distrito @district if @district
            x.Barrio @neighborhood unless @neighborhood.nil?
            x.OtrasSenas @others if @others
          end
        end

        def to_xml(builder,document)
          build_xml(builder,document).to_xml
        end

      end
  end
end
