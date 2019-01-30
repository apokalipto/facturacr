module FE
  class Document
    class OtherContent
      class PriceSmart
        include ActiveModel::Validations
        attr_accessor :transaction_type, :order_number, :order_date, :supplier_number, :store_code
        
        TYPES = ['purchase', 'expense']
        TYPES.each do |t|
          define_method "#{t}?" do
            transaction_type.eql?(t)
          end
        end
        
        NAMESPACES = {
          "xsi:schemaLocation" => "https://invoicer.ekomercio.com/esquemas https://invoices/ekomercio.com/esquemas/ComplementoPricesmartCR_V1_0.xsd",
          "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance",
          "xmlns:retail" => "https://invoicer.ekomercio.com/esquemas"
        }
        
        validates :transaction_type, presence: true, inclusion: TYPES
        validates :supplier_number, presence: true, length: {maximum: 12}
        validates :store_code, presence: true
        validates :order_number, presence: true, if: ->{ purchase? }
        validates :order_date, presence: true, if: ->{ purchase? }
        
        def initialize(args={})
          @transaction_type = args[:transaction_type]
          @supplier_number = args[:supplier_number]
          @store_code = args[:store_code]
          @order_number = args[:order_number]
          @order_date = args[:order_date]
        end
        
        def build_xml(node)
          raise "Invalid Record: #{errors.messages}" unless valid?
          node = Nokogiri::XML::Builder.new if node.nil?         
          node['retail'].Complemento(NAMESPACES) do |xml|
            xml['retail'].NumeroVendedor @supplier_number
            if purchase?
              xml['retail'].OrdenDeCompra do |xml2|
                xml2['retail'].NumeroOrden @order_number
                xml2['retail'].FechaOrden @order_date.xmlschema
              end
            end
            xml['retail'].LugarDeEntrega do |xml2|
              xml2['retail'].GLNLugarDeEntrega @store_code
            end
          end
        end
        
        def to_xml(builder)
          build_xml(builder)
        end
      end
    end
  end
end
