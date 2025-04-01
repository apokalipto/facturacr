module FE
  class Document
    class OtherCharges < Element

        include ActiveModel::Validations

        OTHER_DOCUMENT_TYPES = {

            "01" => "Contribución parafiscal",
            "02" => "Timbre de la Cruz Roja",
            "03" => "Timbre de Benemérito Cuerpo de Bomberos de Costa Rica",
            "04" => "Cobro de un tercero",
            "05" => "Costos de Exportación",
            "06" => "Impuesto de servicio 10%",
            "07" => "Timbre de Colegios Profesionales",
            "99" => "Otros Cargos"
        }.freeze

        attr_accessor :document_type, :collector_id_number, :collector_name, :detail, :percentage, :total_charge, :document_type_other

        validates :document_type, presence: true, inclusion: OTHER_DOCUMENT_TYPES.keys
        validates :collector_id_number, presence: false, if: ->{ document_type.eql?("04") }
        validates :detail, presence: true
        validates :total_charge, presence: true
        validates :collector_name, presence: false, if: ->{ document_type.eql?("04") }

        def initialize(args={})
          @document_type = args[:document_type]
          @collector_id_number=args[:collector_id_number]
          @collector_name = args[:collector_name]
          @detail = args[:detail]
          @percentage =args[:percentage]
          @total_charge = args[:total_charge]
          @document_type_other = args[:document_type_other]
        end

        def build_xml(node, document)
          raise FE::Error.new("other charges invalid",class: self.class, messages: errors.messages) unless valid?

          node = Nokogiri::XML::Builder.new if node.nil?

          node.OtrosCargos do |xml|
              xml.TipoDocumento @document_type if document.version_43?
              xml.TipoDocumentoOC @document_type if document.version_44?
              xml.TipoDocumentoOTROS @document_type_other if document.version_44?
              xml.NumeroIdentidadTercero @third_id_number if document.version_43? && @third_id_number.present?
              xml.NumeroIdentidadTercero @third_id_number if document.version_43? && @third_id_number.present?
              xml.NombreTercero @third_name if @third_name.present?
              xml.Detalle @detail
              xml.Porcentaje @percentage if @percentage.present? &&  document.version_43?
              xml.PorcentajeOC @percentage if @percentage.present? &&  document.version_44?
              xml.MontoCargo @total_charge

          end

        end


    end
  end
end
