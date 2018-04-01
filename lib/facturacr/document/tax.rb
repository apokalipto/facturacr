module FE
  class Document
    class Tax
      include ActiveModel::Validations
      
      TAX_CODES = {
        "01"=>"Impuesto General sobre las Ventas",
        "02"=>"Impuesto Selectivo de Consumo",
        "03"=>"Impuesto Único a los combustibles",
        "04"=>"Impuesto específico de bebidas alcohólicas",
        "05"=>"Impuesto Específico sobre las bebidas envasadas sin contenido alcóholico y jabones de tocador",
        "06"=>"Impuesto a los Productos de Tabaco",
        "07"=>"Servicio",
        "12"=>"Impuesto específico al cemento",
        "98"=>"Otros",
        "08"=>"Impuesto General sobre las ventas diplomáticos",
        "09"=>"Impuesto general sobre las ventas Compras autorizadas",
        "10"=>"Impuesto general sobre las ventas instituciones públicas y otros organismos",
        "11"=>"Impuesto Selectivo de Consumo Compras Autorizadas",
        "99"=>"Otros"
      }
      attr_accessor :code, :rate, :total
      
      validates :code, presence: true, inclusion: TAX_CODES.keys
      def initialize(args={})
        @code = args[:code]
        @rate = args[:rate]
        @total = args[:total]
      end
      
      def build_xml(node)
        raise "Invalida Record: #{errors.messages}" unless valid?
        node = Nokogiri::XML::Builder.new if node.nil?
        
        node.Impuesto do |xml|
          xml.Codigo @code
          xml.Tarifa @rate
          xml.Monto @total
        end
      end
      
    end
  end
end