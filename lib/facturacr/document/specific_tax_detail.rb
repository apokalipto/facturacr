module FE
  class Document
    class SpecificTaxDetail < Element
      include ActiveModel::Validations

      attr_accessor :unit_quantity,:percentage,:proportion,:consumption_unit_volume,:tax_amount

      def initialize(args={})
        @unit_quantity = args[:unit_quantity]
        @percentage = args[:percentage]
        @proportion = args[:proportion]
        @consumption_unit_volume = args[:consumption_unit_volume]
        @tax_amount = args[:tax_amount]
      end


      def build_xml(node, document)
        @document = document
        raise FE::Error.new("specifit tax detail invalid",class: self.class, messages: errors.messages) unless valid?
        node = Nokogiri::XML::Builder.new if node.nil?

        node.DatosImpuestoEspecifico do |xml|
          xml.CantidadUnidadMedida @unit_quantity if @unit_quantity.present?
          xml.Porcentaje @percentage if @percentage.present?
          xml.Proporcion @proportion if @proportion.present?
          xml.VolumenUnidadConsumo @consumption_unit_volume if @consumption_unit_volume.present?
          xml.ImpuestoUnidad @tax_amount if @tax_amount.present?
        end
      end

      def build_combo_item(node, document)
        @document = document
        raise FE::Error.new("tax invalid",class: self.class, messages: errors.messages) unless valid?
        node = Nokogiri::XML::Builder.new if node.nil?

        node.DatosImpuestoEspecificoSurtido do |xml|
          xml.CantidadUnidadMedidaSurtido @unit_quantity if @unit_quantity.present?
          xml.PorcentajeSurtido @percentage if @percentage.present?
          xml.ProporcionSurtido @proportion if @proportion.present?
          xml.VolumenUnidadConsumoSurtido @consumption_unit_volume if @consumption_unit_volume.present?
          xml.ImpuestoUnidadSurtido @tax_amount if @tax_amount.present?
        end
      end


    end
  end
end
