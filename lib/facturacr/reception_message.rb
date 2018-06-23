require 'active_model'

module FE
  class ReceptionMessage
    include ActiveModel::Validations
    
    MESSAGE_TYPES = {
      "1" => "Aceptado",
      "2" => "Aceptacion Parcial",
      "3" => "Rechazado"
    }
    attr_accessor :key, :date, :issuer_id_number, :receiver_id_number, :message, :details, :tax, :total, :number, :receiver_id_type, :security_code, :document_situation
    
    validates :date, presence: true
    validates :issuer_id_number, presence: true, length: {is: 12}
    validates :receiver_id_number, presence: true, length: {is: 12}
    validates :message, presence: true, inclusion: MESSAGE_TYPES.keys
    validates :tax, numericality: true, if: -> { tax.present? }
    validates :total, presence: true, numericality: true
    validates :number, presence: true
    validates :security_code, presence: true, length: {is: 8}
    
    def initialize(args = {})
      @key = args[:key]
      @date = args[:date]
      @issuer_id_number = args[:issuer_id_number]
      @receiver_id_type = args[:receiver_id_type]
      @receiver_id_number = args[:receiver_id_number]
      @message = args[:message].to_s
      @details = args[:details]
      @tax = args[:tax]
      @total = args[:total]
      @number = args[:number].to_i
      @security_code = args[:security_code]
      @document_situation = args[:document_situation]
      @namespaces = {
        "xmlns:xsi"=>"http://www.w3.org/2001/XMLSchema-instance", 
        "xmlns:xsd"=>"http://www.w3.org/2001/XMLSchema",
        "xmlns"=>"https://tribunet.hacienda.go.cr/docs/esquemas/2017/v4.2/mensajeReceptor"
      }
    end
    
    
    def headquarters
      @headquarters ||= "001"
    end
  
    def terminal
      @terminal ||= "00001"
    end 
    
    def sequence
      if @message.eql?("1")
        @document_type = "05"
      elsif @message.eql?("2")
        @document_type = "06"
      elsif @message.eql?("3")
        @document_type = "07"
      end
      cons = ("%010d" % @number)
      "#{headquarters}#{terminal}#{@document_type}#{cons}"
    end
    
    
    
    def build_xml
      raise "Documento inválido: #{errors.messages}" unless valid?
      builder  = Nokogiri::XML::Builder.new
      
      builder.MensajeReceptor(@namespaces) do |xml|
        xml.Clave @key
        xml.NumeroCedulaEmisor @issuer_id_number
        xml.FechaEmisionDoc @date.xmlschema
        xml.Mensaje @message
        xml.DetalleMensaje @details if @details
        xml.MontoTotalImpuesto @tax.to_f
        xml.TotalFactura @total
        xml.NumeroCedulaReceptor @receiver_id_number
        xml.NumConsecutivoReceptor sequence
      end
      
      builder
    end
    
    def generate
      build_xml.to_xml(:save_with => Nokogiri::XML::Node::SaveOptions::AS_XML)
    end
    
    def api_payload
      payload = {}
      payload[:clave] = @key
      payload[:fecha] = @date.xmlschema
      payload[:emisor] = {
        tipoIdentificacion: @receiver_id_type,
        numeroIdentificacion: @receiver_id_number
      }
      payload
    end
    
    
  end
end