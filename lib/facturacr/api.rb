require 'facturacr/api/document_status'

require 'base64'
require 'rest-client'
require 'json'

module FE
  class Api

    attr_accessor :authentication_endpoint, :document_endpoint, :username, :password, :client_id, :errors, :check_location, :refresh_token

    def initialize(configuration = nil)
      @authentication_endpoint = (configuration || FE.configuration).authentication_endpoint
      @document_endpoint = (configuration || FE.configuration).documents_endpoint
      @username = (configuration || FE.configuration).api_username
      @password = (configuration || FE.configuration).api_password
      @client_id = (configuration || FE.configuration).api_client_id
      @errors = {}
    end

    def authenticate
      # Backwards compantibility with configurations that still use contain the token operation in the url.
      url = @authentication_endpoint
      if !@authentication_endpoint.end_with?('token')
        url += "/token"
      end
      response = RestClient.post url, auth_data
      json = JSON.parse(response)
      @token = json["access_token"]
      @refresh_token = json["refresh_token"]

      @token
    rescue => e
      puts "AUTH ERROR: #{e.message}".red
      raise FE::Error.new("authentication error: #{e.message}",class: self.class)
    end

    def logout
      url = @authentication_endpoint
      if @authentication_endpoint.end_with?('token')
        url = url.gsub("token","logout")
      else
        url += "/logout"
      end
      RestClient.post url, logout_data
    rescue => e
      puts "LOGOUT ERROR: #{e.message}".red
    end


    def send_document(payload)
      authenticate
      response = RestClient.post "#{@document_endpoint}/recepcion", payload.to_json, {:Authorization=> "bearer #{@token}", content_type: :json}
      if response.code.eql?(200) || response.code.eql?(202)
        @check_location = response.headers[:location]
        puts "CheckLocation: #{@check_location}"
        return true
      end
    rescue => e
      @errors[:request] = {message: e.message}
      @errors[:response] = e.response if e.respond_to?(:response)
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
        password: @password
        # client_secret: '',
        # scope: ''
      }
    end

    def logout_data
      {
        client_id: @client_id,
        refresh_token: @refresh_token
      }
    end
  end
end
