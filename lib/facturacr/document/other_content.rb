module FE
  class Document
    class OtherContent
      include ActiveModel::Validations
      attr_accessor :implementation
      
      validates :implementation, presence: true


      def initialize(args={})
        @implementation = args[:implementation]
      end
      
      def build_xml(node)
        raise "Invalid Record: #{errors.messages}" unless valid?
        node = Nokogiri::XML::Builder.new if node.nil?         
        node.OtroContenido do |xml|
          @implementation.build_xml(xml)
        end
      end
      
      def to_xml(builder)
        build_xml(builder).to_xml
      end
      
    end
  end
end

require 'facturacr/document/other_content/price_smart'