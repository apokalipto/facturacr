require 'active_model'

module FE
  class Document
    include ActiveModel::Validations

    CONDITIONS = {
      "01"=>"Contado",
      "02"=>"Crédito",
      "03"=>"Consignación",
      "04"=>"Apartado",
      "05"=>"Arrendamiento con Opción de Compra",
      "06"=>"Arrendamiento en Función Financiera",
      "07"=>"Cobro a favor de un tercero",
      "08"=>"Servicios prestados al Estado a crédito ",
      "09"=>"Pago del servicios prestado al Estado ",
      "99"=>"Otros"
    }.freeze
    PAYMENT_TYPES = {
      "01"=>"Efectivo",
      "02"=>"Tarjeta",
      "03"=>"Cheque",
      "04"=>"Transferencia",
      "05"=>"Recaudado por Terceros",
      "99"=>"Otros"
    }.freeze
    DOCUMENT_TYPES = {
      "01"=> "Factura Electronica",
      "02"=> "Nota de débito",
      "03"=> "Nota de crédito",
      "04"=> "Tiquete Electrónico",
      "05"=> "Nota de despacho",
      "06"=> "Contrato",
      "07"=> "Procedimiento",
      "08"=> "Factura Electrónica de compra",
      "09"=> "Factura Electronica de exportación"
    }.freeze
    DOCUMENT_SITUATION = {
      "1" => "Normal",
      "2" => "Contingencia",
      "3" => "Sin Internet"
    }.freeze

    attr_writer :headquarters, :terminal, :key
    attr_accessor :serial, :date, :issuer, :receiver, :condition, :credit_term,
                  :payment_type, :service_type, :reference_information,
                  :regulation, :number, :document_type, :security_code,
                  :items, :references, :namespaces, :summary, :document_situation,
                  :others, :economic_activity, :other_charges, :version
    
    validates :version, presence: true
    validates :economic_activity, presence: true, if: ->{ version.eql?("4.3") }
    validates :date, presence: true
    validates :number, presence: true
    validates :issuer, presence: true
    validates :receiver, presence: true, if: -> {document_type.eql?("01") || document_type.eql?("08")}
    validates :condition, presence: true, inclusion: CONDITIONS.keys
    validates :credit_term, presence: true, if: ->{ condition.eql?("02") }
    validates :document_type, presence: true, inclusion: DOCUMENT_TYPES.keys
    validates :document_situation, presence: true, inclusion: DOCUMENT_SITUATION.keys
    validates :summary, presence: true
    validates :regulation, presence: true, if: ->{ version.eql?("4.2") }
    validates :security_code, presence: true, length: {is: 8}
    validates :references, presence: true, if: -> {document_type.eql?("02") || document_type.eql?("03")}
    validates :items, presence:true
    validate :payment_types_ok?
    
    def initialize
      raise FE::Error "Subclasses must implement this method"
    end

    def document_name
      raise FE::Error "Subclasses must implement this method"
    end

    def key
      @key ||= begin
        raise "Documento inválido: #{errors.messages}" unless valid?
        country = "506"
        day = "%02d" % @date.day
        month = "%02d" % @date.month
        year = "%02d" % (@date.year - 2000)
        id_number = @issuer.identification_document.id_number

        type = @document_situation
        security_code = @security_code

        result = "#{country}#{day}#{month}#{year}#{id_number}#{sequence}#{type}#{security_code}"
        raise "The key is invalid: #{result}" unless result.length.eql?(50)

        result
      end
    end

    def headquarters
      @headquarters ||= "001"
    end

    def terminal
      @terminal ||= "00001"
    end

    def sequence
      cons = ("%010d" % @number)
      "#{headquarters}#{terminal}#{@document_type}#{cons}"
    end
    
    def version_42?
      @version.eql?("4.2")
    end
    
    def version_43?
      @version.eql?("4.3")
    end

    def build_xml
      raise FE::Error.new "Documento inválido", class: self.class, messages: errors.messages unless valid?
      builder  = Nokogiri::XML::Builder.new(encoding: 'UTF-8')

      builder.send(document_tag, @namespaces) do |xml|
        xml.Clave key
        xml.CodigoActividad @economic_activity if version_43?
        xml.NumeroConsecutivo sequence
        xml.FechaEmision @date.xmlschema
        issuer.build_xml(xml, self)
        receiver.build_xml(xml,self) if receiver.present?
        xml.CondicionVenta @condition
        xml.PlazoCredito @credit_term if @credit_term.present? && @condition.eql?("02")

        @payment_type.each do |pt|
          @summary.with_credit_card = true if pt.eql?("02")
          xml.MedioPago pt
        end


        xml.DetalleServicio do |x|
          @items.each do |item|
            item.build_xml(x, self)
          end
        end


        other_charges.build_xml(xml,self) if other_charges.present? && version_43? # see this

        summary.build_xml(xml, self)

        if references.present?
          references.each do |r|
            r.build_xml(xml, self)
          end
        end

        regulation.build_xml(xml,self)  if version_42?

        if others.any?
          xml.Otros do |x|
            @others.each do |o|
              o.build_xml(x, self)
            end
          end
        end
      end

      builder
    end

    def generate
      build_xml.to_xml(:save_with => Nokogiri::XML::Node::SaveOptions::AS_XML)
    end

    def api_payload
      payload = {}
      payload[:clave] = key
      payload[:fecha] = @date.xmlschema
      payload[:emisor] = {
        tipoIdentificacion: @issuer.identification_document.document_type,
        numeroIdentificacion: @issuer.identification_document.id_number
      }
      if @receiver&.identification_document.present?
        payload[:receptor] = {
          tipoIdentificacion: @receiver.identification_document.document_type,
          numeroIdentificacion: @receiver.identification_document.id_number
        }
      end

      payload
    end

    private

    def payment_types_ok?
      errors.add :payment_type, "missing payment type" if @payment_type.nil?
      if @payment_type.is_a?(Array)
        errors.add :payment_type, "invalid payment types: not included" unless @payment_type.all? {|i| PAYMENT_TYPES.include?(i)}
      else
        errors.add :payment_type, "invalid payment type: not array"
      end

    end

  end
end

require_relative 'document/code'
require_relative 'document/exoneration'
require_relative 'document/fax'
require_relative 'document/identification_document'
require_relative 'document/issuer'
require_relative 'document/item'
require_relative 'document/location'
require_relative 'document/phone_type'
require_relative 'document/phone'
require_relative 'document/fax'
require_relative 'document/receiver'
require_relative 'document/reference'
require_relative 'document/regulation'
require_relative 'document/summary'
require_relative 'document/tax'
require_relative 'document/other_text'
require_relative 'document/other_content'
require_relative 'document/other_charges'
