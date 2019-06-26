module FE
  class Document
    class OtherContent < Element
      include ActiveModel::Validations
      attr_accessor :implementation
      
      validates :implementation, presence: true


      def initialize(args={})
        @implementation = args[:implementation]
      end
      
      def build_xml(node, document)
        raise FE::Error.new("other content",class: self.class, messages: errors.messages) unless valid?
        node = Nokogiri::XML::Builder.new if node.nil?         
        node.OtroContenido do |xml|
          @implementation.build_xml(xml, document)
        end
      end
      
      def to_xml(builder,document)
        build_xml(builder,document).to_xml
      end
      
    end
  end
end

require 'facturacr/document/other_content/price_smart'