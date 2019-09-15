require 'awesome_print'

#require 'facturacr'
require_relative 'facturacr/configuration'
require_relative 'facturacr/element'
require_relative 'facturacr/invoice'
require_relative 'facturacr/credit_note'
require_relative 'facturacr/export_invoice'
require_relative 'facturacr/purchase_invoice'
require_relative 'facturacr/debit_note'
require_relative 'facturacr/ticket'
require_relative 'facturacr/document'
require_relative 'facturacr/signed_document'
require_relative 'facturacr/xml_document'
require_relative 'facturacr/api'
require_relative 'facturacr/builder'
require_relative 'facturacr/version'
require_relative 'facturacr/data_provider'
require_relative 'facturacr/signer/signer'
require_relative 'facturacr/reception_message'
require_relative 'facturacr/error'
require_relative 'facturacr/data'

module FE
  class << self
    attr_accessor :configuration
  end

  def self.configure
    if self.configuration.nil?
      self.configuration ||= Configuration.new
    end
    yield(configuration)
    configuration.read_config_file if configuration.file?
  end

  def self.root
    File.dirname __dir__
  end

  def self.bin
    File.join root, 'bin'
  end

end
