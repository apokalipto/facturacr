require 'active_model'

module FE
  class ReceptionMessage
    include ActiveModel::Validations

    MESSAGE_TYPES = {
      "1" => "Aceptado",
      "2" => "Aceptacion Parcial",
      "3" => "Rechazado"
    }.freeze

    TAX_CONDITION={
      "01" => "Genera crédito IVA",
      "02" => "Genera Crédito parcial del IVA",
      "03" => "Bienes de Capital",
      "04" => "Gasto corriente",
      "05" => "Proporcionalidad"
    }.freeze

    NAMESPACES = {
      "4.2" => {
        "xmlns:xsi"=>"http://www.w3.org/2001/XMLSchema-instance",
        "xmlns:xsd"=>"http://www.w3.org/2001/XMLSchema",
        "xmlns"=>"https://tribunet.hacienda.go.cr/docs/esquemas/2017/v4.2/mensajeReceptor"
      },
      "4.3" => {
        "xmlns:xsi"=>"http://www.w3.org/2001/XMLSchema-instance",
        "xmlns:xsd"=>"http://www.w3.org/2001/XMLSchema",
        "xmlns"=>"https://cdn.comprobanteselectronicos.go.cr/xml-schemas/v4.3/mensajeReceptor"
      }
    }

    attr_accessor :key, :date, :issuer_id_number, :receiver_id_number, :message, :details, :economic_activity,
    :tax_condition,:tax_to_credit, :spending_to_apply,:tax, :total, :number, :receiver_id_type, :security_code,
    :document_situation, :issuer_id_type

    validates :date, presence: true
    validates :issuer_id_number, presence: true, length: {is: 12}
    validates :receiver_id_number, presence: true, length: {is: 12}
    validates :message, presence: true, inclusion: MESSAGE_TYPES.keys
    validates :tax_condition, inclusion: TAX_CONDITION.keys, presence:true, if: ->{ version_43? }
    validates :tax, numericality: true, if: -> { tax.present? }
    validates :total, presence: true, numericality: true
    validates :number, presence: true
    validates :security_code, presence: true, length: {is: 8}
    validates :issuer_id_type, presence: true
    validates :receiver_id_type, presence: true

    def initialize(args = {})
      @version = args[:version]
      @key = args[:key]
      @date = args[:date]
      @issuer_id_type = args[:issuer_id_type]
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
      @namespaces = NAMESPACES[@version]
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
      raise FE::Error.new "Documento inválido", class: self.class, messages: errors.messages unless valid?
      builder  = Nokogiri::XML::Builder.new

      builder.MensajeReceptor(@namespaces) do |xml|
        xml.Clave @key
        xml.NumeroCedulaEmisor @issuer_id_number
        xml.FechaEmisionDoc @date.xmlschema
        xml.Mensaje @message
        xml.DetalleMensaje @details if @details
        xml.CodigoActividad @economic_activity if version_43?
        xml.CondicionImpuesto @tax_condition if version_43?
        xml.MontoImpuestoAcreditar @tax_to_credit if version_43?
        xml.MontoTotalDeGastoAplicable @spending_to_apply if version_43?
        xml.MontoTotalImpuesto @tax.to_f if @tax
        xml.TotalFactura @total
        xml.NumeroCedulaReceptor @receiver_id_number
        xml.NumeroConsecutivoReceptor sequence
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
        tipoIdentificacion: infer_id_type(@issuer_id_number),
        numeroIdentificacion: @issuer_id_number
      }
      payload[:receptor] = {
        tipoIdentificacion: infer_id_type(@receiver_id_number),
        numeroIdentificacion: @receiver_id_number
      }
      payload[:consecutivoReceptor] = sequence
      payload
    end

    def infer_id_type(id_number)
      if id_number.to_i.to_s.size == 9
        "01"
      elsif id_number.to_i.to_s.size == 10
        "02"
      elsif id_number.to_i.to_s.size == 11
        "03"
      end
    end

  end

end
