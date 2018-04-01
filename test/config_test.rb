require 'test_helper'

class ConfigTest < Minitest::Test
  
  def teardown
    FE.configuration = nil
    FE.configuration {}
  end
  
  def test_configure_using_file
    FE.configure do |config|
      config.mode = "file"
      config.file_path = "config/config.yml"
      config.environment = 'development'
    end
    config = FE.configuration
    assert_equal "su_usuario_api_atv", config.api_username
    assert_equal "su_password_api_atv", config.api_password
    assert_equal "tmp/llave_criptografica.p12", config.key_path
    assert_equal "99999999999999", config.key_password
  end
  
  def test_config_block_overrides_default_config
    FE.configure do |config|
      config.environment = 'development'
      config.api_username = "myuser"
      config.api_password = "mypassword"
      config.key_path = "my_key_path"
      config.key_password = "my_key_password"
    end
    
    config = FE.configuration
    assert_equal "myuser", config.api_username 
    assert_equal "mypassword", config.api_password 
    assert_equal "my_key_path", config.key_path 
    assert_equal "my_key_password", config.key_password 
  end
  
  def test_can_override_config_values
    FE.configure do |config|
      config.api_username = "initial_value"
    end
    assert_equal FE.configuration.api_username, "initial_value"
    FE.configure do |config|
      config.api_username = "other_value"
    end
    assert_equal FE.configuration.api_username, "other_value"
  end
  
  
end