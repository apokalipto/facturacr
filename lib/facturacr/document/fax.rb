require_relative 'phone_type'

module FE
  class Document
    class Fax < PhoneType
      include ActiveModel::Validations

      attr_accessor :country_code, :number

      def initialize(args = {})
        super('Fax', args[:country_code], args[:number])
      end

    end

  end
end