require 'facturacr/api/document_status'

require 'base64'
require 'rest-client'
require 'json'

module FE
  class Api
    
    attr_accessor :authentication_endpoint, :document_endpoint, :username, :password, :client_id, :errors
    
    def initialize(configuration = nil)
      @authentication_endpoint = (configuration || FE.configuration).authentication_endpoint
      @document_endpoint = (configuration || FE.configuration).documents_endpoint
      @username = (configuration || FE.configuration).api_username
      @password = (configuration || FE.configuration).api_password
      @client_id = (configuration || FE.configuration).api_client_id
      @errors = {}
    end
    
    def authenticate
      response = RestClient.post @authentication_endpoint, auth_data
      @token = JSON.parse(response)["access_token"]
      
      @token
    rescue => e
      puts "AUTH ERROR: #{e.message}".red
      raise e
    end
    
        
    def send_document(payload)
      authenticate    
      response = RestClient.post "#{@document_endpoint}/recepcion", payload.to_json, {:Authorization=> "bearer #{@token}", content_type: :json}
      return true if response.code.eql?(200) || response.code.eql?(202)
    rescue => e
      @errors[:request] = {message: e.message, response: e.response}
      return false      
    end
    
    def get_document_status(key)
      authenticate
      response = RestClient.get "#{@document_endpoint}/recepcion/#{key}", {:Authorization=> "bearer #{@token}", content_type: :json}
      return FE::Api::DocumentStatus.new(response)
    end
    
    def get_document(key)
      authenticate
      response = RestClient.get "#{@document_endpoint}/comprobantes/#{key}", {:Authorization=> "bearer #{@token}", content_type: :json}
      JSON.parse(response)
    end
    
    def get_documents
      authenticate
      response = RescClient.get "#{@document_endpoint}/comprobantes", {:Authorization => "bearer #{@token}", content_type: :json }
      JSON.parse(response)
    end
        
    
    private
    
    
    
    def auth_data
      {
        grant_type: 'password',
        client_id: @client_id,
        username: @username,
        password: @password,
        client_secret: '',
        scope: ''
      }
    end
  end
end