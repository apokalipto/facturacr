require 'yaml'
require 'erb'
module FE
  class Configuration
    
    attr_accessor :api_username
    attr_accessor :api_password
    attr_accessor :key_path
    attr_accessor :key_password
    attr_accessor :documents_endpoint
    attr_accessor :authentication_endpoint
    attr_accessor :api_client_id
    attr_accessor :environment
    attr_accessor :file_path
    attr_accessor :mode
    
    
    def initialize
      @environment = "development"
      @mode = :manual
      @api_username = "changeme"
      @api_password = "changeme"
      @key_path = "resources/test.p12"
      @key_password = "test123"
      @api_client_id = 'api-stag'
      @documents_endpoint = "https://api.comprobanteselectronicos.go.cr/recepcion-sandbox/v1"
      @authentication_endpoint = "https://idp.comprobanteselectronicos.go.cr/auth/realms/rut-stag/protocol/openid-connect/token"
    end
    
    def read_config_file
      if file? && @file_path && File.exists?(@file_path)
        template = ERB.new(File.read(@file_path))
        result = YAML.load(template.result(binding))
        result[@environment].each do |k,v|
          if respond_to?(k)
            self.send("#{k}=",v)
          end
        end
      end
    end
    
    def manual?
      @mode.to_sym.eql?(:manual)
    end
    
    def file?
      @mode.to_sym.eql?(:file)
    end
    
  end
end