# FE

Esta librería implementa los procesos de facturación electrónica del Ministerio de Hacienda de Costa Rica en Ruby. Puede ser utilizada como punto de partida para realizar la integración necesaria con el Ministerio de Hacienda.

Actualmente cuenta con las siguientes características:

- Generación de XML
- Firmado de XML (utilizando JAVA)
- Comunicación con el API del ministerio de hacienda
- Línea de comando para realizar los procesos

## Instalación

Agregue la siguiente línea en el Gemfile

```ruby
gem 'facturacr'
```

Execute el comando

    $ bundle

O instale el gem

    $ gem install facturacr

## Utilziación

Para generar documentos:

```ruby
	require 'facturacr'

	id_document = FE::Document::IdentificationDocument.new type: "01", number: "112345678"
	phone = FE::Document::Phone.new country_code: "506", "22222222" 
	location = FE::Document::Location.new province: "1",county: "01", district: "01", others: "Otras señas"
	issuer = FE::Document::Issuer.new name: "EMISON EJEMPLO", identification_document: id_document, location: location, phone: phone, email: "emisor@ejemplo.com"

	reciever_id_document = FE::Document::IdentificationDocument.new type: "02", number: "3102123456"
	receiver = FE::Document::Receiver.new name: "RECEPTOR EJEMPLO", identification_document: id_document

	items = []
	items << FE::Document::Item.new(code: "001", line_number: 1, quantity: 1, unit: "Sp", description: "Desarrollo de Software y Mantenimiento", unit_price: 300, subtotal: 300, net_total: 300, total: 300)
	taxes = [FE::Document::Tax.new(code: "01", rate: 13, total: (100 * 0.13))]
	items << FE::Document::Item.new(code: "002", line_number: 2, quantity: 2, unit: "Unid", description: "Impresora de POS", unit_price: 50, total: 100, taxes: taxes, net_total: 113, subtotal: 100)
	summary = FE::Document::Summary.new currency: "USD", exchange_rate: 575, services_exent_total: 300, goods_taxable_total: 100, exent_total: 300, taxable_total: 100, subtotal: 400, gross_total: 400, tax_total: 13, net_total: 413


	invoice = FE::Invoice.new date: date, issuer: issuer, receiver: receiver, number: number, items: items, condition: condition, credit_term: credit_term, summary: summary, security_code: "12345678", document_situation: "1"

	# Para generar el XML como string
	xml = invoice.generate
	
	# Escribir el archivo
	File.open("/path/to/file.xml","w"){|f| f.write(xml)}
```

Para configurar el API / Firmador:
```ruby
	FE.configure do |config|
		config.api_username "su_usuario_api_atv"
  	config.api_password = "su_password_api_atv"
  	config.key_path = "tmp/llave_criptografica.p12"
  	config.key_password = "99999999999999"

  	# api hacienda: valores default
  	config.api_client_id = 'api-stag'
  	config.documents_endpoint = "https://api.comprobanteselectronicos.go.cr/recepcion-sandbox/v1"
  	config.authentication_endpoint = "https://idp.comprobanteselectronicos.go.cr/auth/realms/rut-stag/protocol/openid-connect/token"s
	end
```

Para firmar documentos. (Debe tener java instalado)
```ruby
  signer = FE::JavaSigner.new FE.configuration.key_path, FE.configuration.key_password, "/path/to/unsigned.xml", "/path/to/signed.xml"
  signer.sign
```


Para enviar documentos al API
```ruby
	api = FE::API.new
	
	# document is FE::Document
  signed_document = FE::SignedDocument.new(document,path)
  api = FE::Api.new
  if api.send_document(signed_document.payload)
		puts "Document sent!"
	else
		puts "Error: #{api.errors}"
	end
```

Para chequear el estatus del documento
```ruby
	api = FE::API.new
  FE::Utils.configure(options[:config_file])
  api = FE::Api.new
  document_status = api.get_document_status(key)
  puts document_status.to_h
	#=> {key: "50601011600310112345600100010100000000011999999999", date: "2016-01-01T00:00:00-0600", status: "aceptado", datails: ""}
```

## Lína de comando

Para utilziar la línea de comando y generar documentos de prueba, debe generar los archivos de configuración en un directorio temporal. Navegue al directorio donde desee ejectuar el proceso:

	$ facturacr setup /path/to/directory	

Modifique los archivos config.yml y data.yml para utilziar la línea de comando

Para generar documentos:

	$ facturacr generate help
	
	Commands:
	  facturacr generate credit_note     # generates an XML credit note
	  facturacr generate debit_note      # generates an XML debit note
	  facturacr generate help [COMMAND]  # Describe subcommands or one specific subcommand
	  facturacr generate invoice         # generates an XML invoice

Por ejemplo, para generar una factura

	
	$ facturacr generate invoice --number 112
	
	Details:
	ISSUER: Cédula Jurídica 3102123456 - EMISOR EJEMPLO
	RECEIVER: Cédula Fisica 111900158 - RECEPTOR EJEMPLO
	KEY: 50601041800310212345600100001010000000112199999999	

Adicionalmente se pueden especificar las opciones para firma y enviar a hacienda

	$ facturacr generate invoice --number 112 --sign --send
	
	Details:
	ISSUER: Cédula Jurídica 3102123456 - EMISOR EJEMPLO
	RECEIVER: Cédula Fisica 111900158 - RECEPTOR EJEMPLO
	KEY: 50601041800310212345600100001010000000112199999999
	
	=> SIGN ...............
	=> SEND TO API .................
	Document Sent
	KEY: 50601041800310212345600100001010000000112199999999
	Wait 5 seconds before check...
	{
	        :key => "50601041800310212345600100001010000000112199999999",
	       :date => "2018-04-01T01:00:30-06:00",
	     :status => "aceptado",
	    :details => "Este comprobante fue procesado en el ambiente de pruebas, por lo cual no tiene validez para fines tributarios."
	}	


Para firmar documentos

	$ facturacr sign_document /path/to/unsigned.xml /path/to/signed.xml

Para enviar documentos

	$ facturacr send_document /path/to/signed.xml		

## To Do

- Mejorar y extender la generación de XML
- Implemntar un mapeo más sencillo para generación de XML
- Implementar Aceptación y Rechazo
- Finalizar el firmador en ruby

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/apokalipto/facturacr.

