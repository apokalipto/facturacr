require 'json'
require 'rest-client'
require 'active_support/core_ext/hash/indifferent_access'

module FE
  class Data
    
    ENDPOINT = "https://api.hacienda.go.cr"
    
    def self.contributor(id_number)
      response = RestClient.get "#{ENDPOINT}/fe/ae?identificacion=#{id_number}"
      return JSON.parse(response.body).with_indifferent_access
    rescue => e
      puts "FE::Data.contributor(#{id_number}) #{e.message}"
      return nil
    end
    
    def self.exchange_rate(currency = "USD")
      if currency.eql?("USD")
        path = "tc/dolar"
      elsif currency.eql?("EUR")
        path = "tc/euro"
      else
        raise "#{currency} is not a valid argument"
      end
      response = RestClient.get "#{ENDPOINT}/indicadores/#{path}"
      return JSON.parse(response.body).with_indifferent_access
    rescue => e
      puts "FE::Data.exchange_rate(#{currency}) #{e.message}"
      return nil
    end
    
    def self.exonerations(id_number)
      response = RestClient.get "#{ENDPOINT}/fe/ex?identificacion=#{id_number}"
      return JSON.parse(response.body).with_indifferent_access
    rescue => e
      puts "FE::Data.exonerations(#{id_number}) #{e.message}"
      return nil
    end
  end
end