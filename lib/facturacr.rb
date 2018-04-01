require 'awesome_print'
require 'facturacr'
require 'facturacr/configuration'
require 'facturacr/document'
require 'facturacr/invoice'
require 'facturacr/credit_note'
require 'facturacr/debit_note'
require 'facturacr/ticket'
require 'facturacr/signed_document'
require 'facturacr/xml_document'
require 'facturacr/api'
require 'facturacr/builder'
require 'facturacr/version'
require 'facturacr/signer/signer'

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
