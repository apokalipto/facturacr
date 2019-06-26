require 'openssl'
require 'base64'
require "rexml/document"
require "rexml/xpath"

module FE
  class Signer
    C14N            = "http://www.w3.org/TR/2001/REC-xml-c14n-20010315" #"http://www.w3.org/2001/10/xml-exc-c14n#"
    DSIG            = "http://www.w3.org/2000/09/xmldsig#"
    NOKOGIRI_OPTIONS = Nokogiri::XML::ParseOptions::STRICT | Nokogiri::XML::ParseOptions::NONET | Nokogiri::XML::ParseOptions::NOENT
    RSA_SHA1        = "http://www.w3.org/2000/09/xmldsig#rsa-sha1"
    RSA_SHA256      = "http://www.w3.org/2001/04/xmldsig-more#rsa-sha256"
    RSA_SHA384      = "http://www.w3.org/2001/04/xmldsig-more#rsa-sha384"
    RSA_SHA512      = "http://www.w3.org/2001/04/xmldsig-more#rsa-sha512"
    SHA1            = "http://www.w3.org/2000/09/xmldsig#sha1"
    SHA256          = "http://www.w3.org/2001/04/xmlenc#sha256"
    SHA384          = "http://www.w3.org/2001/04/xmldsig-more#sha384"
    SHA512          = "http://www.w3.org/2001/04/xmlenc#sha512"
    ENVELOPED_SIG   = "http://www.w3.org/2000/09/xmldsig#enveloped-signature"
    INC_PREFIX_LIST = "#default samlp saml ds xs xsi md"
    NAMESPACES =      "#default ds xs xsi xades xsd"

    XADES           = "http://uri.etsi.org/01903/v1.3.2#"
    XADES141        = "http://uri.etsi.org/01903/v1.4.1#"
    SIGNATURE_POLICY_42 = "https://tribunet.hacienda.go.cr/docs/esquemas/2016/v4/Resolucion%20Comprobantes%20Electronicos%20%20DGT-R-48-2016.pdf"
    
    XMLNS_MAP_42 = {
      "FacturaElectronica" => "https://tribunet.hacienda.go.cr/docs/esquemas/2017/v4.2/facturaElectronica",
      "NotaCreditoElectronica" => "https://tribunet.hacienda.go.cr/docs/esquemas/2017/v4.2/notaCreditoElectronica",
      "TiqueteElectronico" => "https://tribunet.hacienda.go.cr/docs/esquemas/2017/v4.2/tiqueteElectronico",
      "NotaDebitoElectronica" => "https://tribunet.hacienda.go.cr/docs/esquemas/2017/v4.2/notaDebitoElectronica",
      "MensajeReceptor" => "https://tribunet.hacienda.go.cr/docs/esquemas/2017/v4.2/mensajeReceptor"
    }
    
    XMLNS_MAP_43 = {
      "FacturaElectronica" => "https://cdn.comprobanteselectronicos.go.cr/xml-schemas/v4.3/facturaElectronica",
      "NotaCreditoElectronica" => "https://cdn.comprobanteselectronicos.go.cr/xml-schemas/v4.3/notaCreditoElectronica",
      "TiqueteElectronico" => "https://cdn.comprobanteselectronicos.go.cr/xml-schemas/v4.3/tiqueteElectronico",
      "NotaDebitoElectronica" => "https://cdn.comprobanteselectronicos.go.cr/xml-schemas/v4.3/notaDebitoElectronica",
      "MensajeReceptor" => "https://cdn.comprobanteselectronicos.go.cr/xml-schemas/v4.3/mensajeReceptor"
    }   
    
    def initialize(args = {})
      document_provider = args[:xml_provider]
      key_provider = args[:key_provider]
      pin = args[:pin]
      raise ArgumentError , "Los argumentos no son válidos" if document_provider.nil? || key_provider.nil? || pin.nil?
      @doc = Nokogiri::XML(document_provider.contents) do |config|
        config.options = Nokogiri::XML::ParseOptions::NOBLANKS | Nokogiri::XML::ParseOptions::NOENT | Nokogiri::XML::ParseOptions::NOENT
      end
      @p12 = OpenSSL::PKCS12.new(key_provider.contents,args[:pin])
      @x509 = @p12.certificate
      @output_path = args[:output_path]
      @document_tag = @doc.elements.first.name
      @version = @doc.elements.first.namespace.href.scan(/v4\..{1}/).first[1..-1]
      @xmlns_map = XMLNS_MAP_42 if @version.eql?("4.2")
      @xmlns_map = XMLNS_MAP_43 if @version.eql?("4.3")
    end
        
    def sign
      #Build parts for Digest Calculation
      key_info = build_key_info_element
      signed_properties = build_signed_properties_element
      signed_info_element = build_signed_info_element(key_info,signed_properties)
      
      # Compute Signature
      signed_info_canon = canonicalize_document(signed_info_element)
      signature_value = compute_signature(@p12.key,algorithm(RSA_SHA256).new,signed_info_canon)
                  
      ds = Nokogiri::XML::Node.new("ds:Signature", @doc)
      ds["xmlns:ds"] = DSIG
      #ds["Id"] = SIGNATURE_ID#"xmldsig-#{uuid}"
      ds["Id"] = "xmldsig-#{uuid}"
      #ds.add_child(Nokogiri::XML(signed_info_without_ns).root)
      ds.add_child(signed_info_element.root)
      
      sv = Nokogiri::XML::Node.new("ds:SignatureValue", @doc)
      #sv["Id"] = SIGNATURE_VALUE#"xmldsig-#{uuid}-sigvalue"
      sv["Id"] = "xmldsig-#{uuid}-sigvalue"
      sv.content = signature_value
      ds.add_child(sv)
      
      ds.add_child(key_info.root)
      
      
      dsobj = Nokogiri::XML::Node.new("ds:Object",@doc)
      dsobj["Id"] = "xades-obj-#{uuid}"#XADES_OBJECT_ID
      qp = Nokogiri::XML::Node.new("xades:QualifyingProperties",@doc)
      qp["xmlns:xades"] = XADES
      #qp["Target"] = "##{SIGNATURE_ID}"#"#xmldsig-#{uuid}"
      qp["Target"] = "#xmldsig-#{uuid}"
      qp["Id"] = "QualifyingProperties-#{uuid}"
      qp.add_child(signed_properties.root)
      
      dsobj.add_child(qp)
      ds.add_child(dsobj)
      @doc.root.add_child(ds)
      
      File.open(@output_path,"w"){|f| f.write(@doc.to_xml(:save_with=>Nokogiri::XML::Node::SaveOptions::AS_XML).gsub(/\r|\n/,""))} if @output_path
      
      @doc.to_xml(:save_with=>Nokogiri::XML::Node::SaveOptions::AS_XML).gsub(/\r|\n/,"")
    end
    
    
    private
    
    def build_key_info_element
      builder  = Nokogiri::XML::Builder.new
      attributes = {
        "xmlns" => @xmlns_map[@document_tag],
        "xmlns:ds" => "http://www.w3.org/2000/09/xmldsig#",
        "xmlns:xsd" => "http://www.w3.org/2001/XMLSchema",
        "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance",
        "Id"=>"xmldsig-#{uuid}-keyinfo"
      }
      
      builder.send("ds:KeyInfo", attributes) do |ki|
        ki.send("ds:X509Data") do |kd|
          kd.send("ds:X509Certificate", @x509.to_pem.to_s.gsub("-----BEGIN CERTIFICATE-----","").gsub("-----END CERTIFICATE-----","").gsub(/\n|\r/, ""))
        end
        ki.send("ds:KeyValue") do |kv|
          kv.send("ds:RSAKeyValue") do |rv|
            rv.send("ds:Modulus", Base64.encode64(@x509.public_key.params["n"].to_s(2)).gsub("\n",""))
            rv.send("ds:Exponent", Base64.encode64(@x509.public_key.params["e"].to_s(2)).gsub("\n",""))
          end
        end
      end
      builder.doc
    end
    
    def build_signed_properties_element
      cert_digest = compute_digest(@x509.to_der,algorithm(SHA256))
      policy_digest = compute_digest(@x509.to_der,algorithm(SHA256))
      signing_time = DateTime.now.rfc3339
      builder  = Nokogiri::XML::Builder.new
      attributes = {
        "xmlns"=>@xmlns_map[@document_tag],
        "xmlns:ds" => "http://www.w3.org/2000/09/xmldsig#",
        "xmlns:xades" => "http://uri.etsi.org/01903/v1.3.2#",
        "xmlns:xsd" => "http://www.w3.org/2001/XMLSchema",
        "xmlns:xsi"=>"http://www.w3.org/2001/XMLSchema-instance",
        "Id" => "xmldsig-#{uuid}-signedprops"
      }
      builder.send("xades:SignedProperties", attributes) do |sp|
        sp.send("xades:SignedSignatureProperties") do |ssp|
          ssp.send("xades:SigningTime", signing_time)
          ssp.send("xades:SigningCertificate") do |sc|
            sc.send("xades:Cert") do |c|
              c.send("xades:CertDigest") do |xcd|
                xcd.send("ds:DigestMethod", {"Algorithm"=>SHA256})
                xcd.send("ds:DigestValue", cert_digest)
              end
              c.send("xades:IssuerSerial") do |is|
                is.send("ds:X509IssuerName", @x509.issuer.to_a.reverse.map{|c| c[0..1].join("=")}.join(", "))
                is.send("ds:X509SerialNumber", @x509.serial.to_s)
              end
            end
          end
          
          ssp.send("xades:SignaturePolicyIdentifier") do |spi|
            spi.send("xades:SignaturePolicyId") do |spi2|
              spi2.send("xades:SigPolicyId") do |spi3|
                spi3.send("xades:Identifier", SIGNATURE_POLICY_42)
                spi3.send("xades:Description")
              end
              
              spi2.send("xades:SigPolicyHash") do |sph|
                sph.send("ds:DigestMethod", {"Algorithm"=>"http://www.w3.org/2000/09/xmldsig#sha1"})
                sph.send("ds:DigestValue", "V8lVVNGDCPen6VELRD1Ja8HARFk=")
              end
            end
          end
          
        end
        sp.send("xades:SignedDataObjectProperties") do |sdop|
          sdop.send("xades:DataObjectFormat", {"ObjectReference"=>"#xmldsig-#{uuid}-ref0"}) do |dof|
            dof.send("xades:MimeType","text/xml")
            dof.send("xades:Encoding", "UTF-8")
          end
        end
      end
      
      builder.doc
    end
    
    def build_signed_info_element(key_info_element, signed_props_element)
      
      builder = builder  = Nokogiri::XML::Builder.new
      attributes = {
        "xmlns"=>@xmlns_map[@document_tag],
        "xmlns:ds" => "http://www.w3.org/2000/09/xmldsig#",
        "xmlns:xsd" => "http://www.w3.org/2001/XMLSchema",
        "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance"
      }
      builder.send("ds:SignedInfo", attributes) do |si|
        si.send("ds:CanonicalizationMethod", { "Algorithm"=>C14N })
        si.send("ds:SignatureMethod", {"Algorithm"=>RSA_SHA256})

        si.send("ds:Reference",{"Id"=>"xmldsig-#{uuid}-ref0", "URI"=>""}) do |r|
          r.send("ds:Transforms") do |t|
            t.send("ds:Transform", {"Algorithm"=>ENVELOPED_SIG})
          end
          r.send("ds:DigestMethod", {"Algorithm"=> SHA256})
          r.send("ds:DigestValue", digest_document(@doc,SHA256))
        end
        si.send("ds:Reference",{"Id"=>"xmldsig-#{uuid}-ref1", "URI"=>"#xmldsig-#{uuid}-keyinfo"}) do |r|
          r.send("ds:DigestMethod", {"Algorithm"=> SHA256})
          r.send("ds:DigestValue", digest_document(key_info_element, SHA256, true))
        end
                
        si.send("ds:Reference",{"Type"=>"http://uri.etsi.org/01903#SignedProperties", "URI"=>"#xmldsig-#{uuid}-signedprops"}) do |r|
          r.send("ds:DigestMethod", {"Algorithm"=> SHA256})
          r.send("ds:DigestValue", digest_document(signed_props_element, SHA256, true))
        end
      end
      
            
      builder.doc
    end
    
    def digest_document(doc, digest_algorithm=SHA256, strip=false)
      compute_digest(canonicalize_document(doc,strip),algorithm(digest_algorithm))
    end
    
    def canonicalize_document(doc,strip=false)
      doc.canonicalize(canon_algorithm(C14N),NAMESPACES.split(" "))
    end
    
    
    def uuid
      @uuid ||= SecureRandom.uuid
    end
    
    def canon_algorithm(element)
     algorithm = element
     

     case algorithm
       when "http://www.w3.org/TR/2001/REC-xml-c14n-20010315",
            "http://www.w3.org/TR/2001/REC-xml-c14n-20010315#WithComments"
         Nokogiri::XML::XML_C14N_1_0
       when "http://www.w3.org/2006/12/xml-c14n11",
            "http://www.w3.org/2006/12/xml-c14n11#WithComments"
         Nokogiri::XML::XML_C14N_1_1
       else
         Nokogiri::XML::XML_C14N_EXCLUSIVE_1_0
     end
    end

    def algorithm(element)
     algorithm = element
     if algorithm.is_a?(REXML::Element)
       algorithm = element.attribute("Algorithm").value
     elsif algorithm.is_a?(Nokogiri::XML::Element)
       algorithm = element.xpath("//@Algorithm", "xmlns:ds" => "http://www.w3.org/2000/09/xmldsig#").first.value
     end

     algorithm = algorithm && algorithm =~ /(rsa-)?sha(.*?)$/i && $2.to_i

     case algorithm
     when 256 then OpenSSL::Digest::SHA256
     when 384 then OpenSSL::Digest::SHA384
     when 512 then OpenSSL::Digest::SHA512
     else
       OpenSSL::Digest::SHA1
     end
    end

    def compute_signature(private_key, signature_algorithm, document)
      Base64.encode64(private_key.sign(signature_algorithm, document)).gsub(/\r|\n/, "")
    end

    def compute_digest(document, digest_algorithm)
     digest = digest_algorithm.digest(document)
     Base64.encode64(digest).strip!
    end
     
  end
  
  class JavaSigner
    
    def initialize(key_file,password,path,out_path)
      @key_file = key_file
      @password = password
      @path = path
      @out_path = out_path
    end
    
    def sign
      null_device = Gem.win_platform? ? "/nul" : "/dev/null" 
      system("java -jar #{FE.bin}/signer/signer.jar #{@key_file} #{@password} #{@path} #{@out_path} 1>#{null_device} 2>#{null_device}")
    end
  end
end