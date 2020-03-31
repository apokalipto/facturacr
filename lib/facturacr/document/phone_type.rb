module FE
  class Document
    class PhoneType < Element
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
      
      def build_xml(node, document)
        raise FE::Error.new("phone type invalid",class: self.class, messages: errors.messages) unless valid?
        
        node = Nokogiri::XML::Builder.new if node.nil?         
        node.send(tag_name) do |xml|
          xml.CodigoPais country_code
          xml.NumTelefono number
        end
      end
      
      def to_xml(builder,document)
        build_xml(builder, document).to_xml
      end
    end
  end
end