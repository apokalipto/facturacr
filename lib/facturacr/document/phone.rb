require "facturacr/document"
require 'facturacr/document/phone_type'
require 'active_model'

module FE
  class Document
    class Phone < PhoneType
      include ActiveModel::Validations

      attr_accessor :country_code, :number

      def initialize(args = {})
        super('Telefono', args[:country_code],args[:number])
      end

    end
  end
end