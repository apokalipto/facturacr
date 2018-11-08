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
      attr_accessor :code, :rate, :total, :exoneration
      
      validates :code, presence: true, inclusion: TAX_CODES.keys
      # It is a mandatory field when a tax is added. And it is a decimal number that can be composed of 4 integers and 2 decimals
      validates :rate, presence: true, format: { with: /\A\d{1,4}(\.\d{0,2})?\z/ }
      # It is a mandatory field when a tax is added, it is obtained from the multiplication of the "subtotal" field by "tax rate"
      # And is a decimal number that can be composed of 13 integers and 5 decimals
      validates :total, presence: true, format: { with: /\A\d{1,13}(\.\d{0,5})?\z/ }

      def initialize(args={})
        @code = args[:code]
        @rate = args[:rate]
        @total = args[:total]
        @exoneration = args[:exoneration]
      end
      
      def build_xml(node)
        raise "Invalida Record: #{errors.messages}" unless valid?
        node = Nokogiri::XML::Builder.new if node.nil?
        
        node.Impuesto do |xml|
          xml.Codigo @code
          xml.Tarifa @rate
          xml.Monto @total
          if @exoneration.present?
            @exoneration.build_xml(xml)
          end
        end
      end
      
    end
  end
end