require_relative 'test_helper'

class FeDataTest < Minitest::Test
  
  def test_contributor
    personal = "111900158"
    contributor = FE::Data.contributor(personal)
    refute_nil contributor, "contributor"
    refute_nil contributor[:nombre], "contributor['nombre']"
    refute_nil contributor[:tipoIdentificacion], "contributor['tipoIdentificacion']"
    refute_nil contributor[:actividades], "contributor['actividades']"
  end
  
  def test_exchange_rates 
    er = FE::Data.exchange_rate("USD")
    refute_nil er, "exchange_rate USD"
    refute_nil er[:venta], "venta"
    refute_nil er[:compra], "venta"
    refute_nil er[:venta][:fecha], "venta fecha USD"
    refute_nil er[:venta][:valor], "venta valor USD"
    refute_nil er[:compra][:fecha], "compra fecha USD"
    refute_nil er[:compra][:valor], "compra valor USD"
    
    er = FE::Data.exchange_rate("EUR")
    refute_nil er, "exchange_rate EUR"
    refute_nil er[:fecha], "fecha EUR"
    refute_nil er[:valor], "valor EUR"
    
  end
  
  def test_exonerations
  end
end