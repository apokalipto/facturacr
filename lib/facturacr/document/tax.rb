module FE
  class Document
    class Tax
      include ActiveModel::Validations

      TAX_CODES = {
        "01"=>"Impuesto al Valor Agregado",
        "02"=>"Impuesto Selectivo de Consumo",
        "03"=>"Impuesto Único a los combustibles",
        "04"=>"Impuesto específico de bebidas alcohólicas",
        "05"=>"Impuesto Específico sobre las bebidas envasadas sin contenido alcóholico y jabones de tocador",
        "06"=>"Impuesto a los Productos de Tabaco",
        "07"=>"IVA (cálculo especial)",
        "08"=>"IVA Régimen de Bienes Usados (Factor)",
        "12"=>"Impuesto específico al cemento",
        "99"=>"Otros"
      }.freeze
      RATE_CODES ={
        "01"=>"Tarifa 0% (Exento)",
        "02"=>"Tarifa reducida 1%",
        "03"=>"Tarifa reducida 2%",
        "04"=>"Tarifa reducida 4%",
        "05"=>"Transitorio 0%",
        "06"=>"Transitorio 4% ",
        "07"=>"Transitorio 8% ",
        "08"=>"Tarifa general 13%"
      }.freeze
      attr_accessor :code, :rate_code ,:rate, :iva_factor, :total, :exoneration, :total_exportation

      validates :rate_code, inclusion: RATE_CODES.keys, presence: true, if:->{ FE.configuration.version_43?}
      validates :code, presence: true, inclusion: TAX_CODES.keys
    #  validates :total_exportation, presence: false, if:->{:document_type.eql?("01") || :document_type.eql?("08") || :document_type.eql?("04")}
      # It is a mandatory field when a tax is added. And it is a decimal number that can be composed of 4 integers and 2 decimals
      validates :rate, presence: true, format: { with: /\A\d{1,4}(\.\d{0,2})?\z/ }
      # It is a mandatory field when a tax is added, it is obtained from the multiplication of the "subtotal" field by "tax rate"
      # And is a decimal number that can be composed of 13 integers and 5 decimals
      validates :total, presence: true, format: { with: /\A\d{1,13}(\.\d{0,5})?\z/ }
      validates :exoneration, presence:false, if: ->{:document_type.eql?("09")}
    #  validates :iva_factor, presence: true, if: ->{  }

      def initialize(args={})
        @code = args[:code]
        @rate_code = args[:rate_code]
        @rate = args[:rate]
        @iva_factor = args[:iva_factor]
        @total = args[:total]
        @exoneration = args[:exoneration]
        @total_exportation = args[:total_exportation]

      end


      def build_xml(node)

        raise "Invalida Record: #{errors.messages}" unless valid?
        node = Nokogiri::XML::Builder.new if node.nil?

        node.Impuesto do |xml|
          xml.Codigo @code
          xml.CodigoTarifa @rate_code if @rate_code.present? && FE.configuration.version_43?
          xml.Tarifa @rate
          xml.FactorIva @iva_factor if @iva_factor.present? && FE.configuration.version_43?
          xml.Monto @total
          xml.MontoExportacion @total_exportation if @total_exportation.present? && FE.configuration.version_43?

         if exoneration.present?
         exoneration.build_xml(xml)
         end

        end
      end


    end
  end
end
