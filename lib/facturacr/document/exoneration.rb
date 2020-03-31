module FE
  class Document
    class Exoneration < Element
      include ActiveModel::Validations


      DOCUMENT_TYPES = {
        "01" => "Compras Autorizadas",
        "02" => "Ventas exentas a diplomáticos",
        "03" => "Autorizado por Ley especial",
        "04" => "Exenciones Dirección General de Hacienda",
        "05" => "Transitorio V",
        "06" => "Transitorio IX",
        "07" => "Transitorio XVII",
        "99" => "Otros"
      }.freeze
      attr_accessor :document_type, :document_number, :institution, :date, :total_tax, :percentage, :net_total

      validates :document_type, presence: true, inclusion: DOCUMENT_TYPES.keys
      validates :document_number, presence: true, length: { maximum: 40 }
      validates :institution, presence: true, length: { maximum: 160 }
      validates :date, presence: true
      validates :total_tax,presence: true
      validates :percentage, presence: true, numericality: {greater_than_or_equal_to: 0, less_than_or_equal_to: 100, only_integer: true}
      

      def initialize(args={})
        @document_type = args[:document_type]
        @document_number = args[:document_number]
        @institution = args[:institution]
        @date = args[:date]
        @total_tax = args[:total_tax]
        @percentage = args[:percentage]
      end

      def build_xml(node, document)
        @document = document
        raise FE::Error.new("invalid exoneration",class: self.class, messages: errors.messages) unless valid?
        node = Nokogiri::XML::Builder.new if node.nil?

        node.Exoneracion do |xml|
          xml.TipoDocumento @document_type
          xml.NumeroDocumento @document_number
          xml.NombreInstitucion @institution
          xml.FechaEmision @date.xmlschema
          xml.PorcentajeExoneracion @percentage
          xml.MontoExoneracion @total_tax
        end
      end


    end
  end
end
