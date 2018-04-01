module FE
  class Document
    class Regulation
      include ActiveModel::Validations
      
      attr_accessor :number, :date
      
      validates :number, presence: true
      validates :date, presence: true
      
      def initialize(args={})
        @number = args[:number] ||= "DGT-R-48-2016"
        @date = args[:date] ||= "20-02-2017 13:22:22"
      end
      
      def build_xml(node)
        raise "Regulation Invalid: #{errors.messages}" unless valid?
        node = Nokogiri::XML::Builder.new if node.nil?
        node.Normativa do |xml|
          xml.NumeroResolucion @number
          xml.FechaResolucion @date
        end
      end
    end
  end
end