require 'openssl'
require 'base64'
require "rexml/document"
require "rexml/xpath"

module FE
  class Signer
    REXML::Document::entity_expansion_limit = 0
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
    SIGNATURE_POLICY = "https://tribunet.hacienda.go.cr/docs/esquemas/2016/v4/Resolucion%20Comprobantes%20Electronicos%20%20DGT-R-48-2016.pdf"
    
    
    def initialize(key_path, key_password,input_xml, output_path=nil)
      @doc = REXML::Document.new(File.read(input_xml))
      @doc.context[:attribute_quote] = :quote
      @doc << REXML::XMLDecl.new(REXML::XMLDecl::DEFAULT_VERSION,REXML::XMLDecl::DEFAULT_ENCODING, REXML::XMLDecl::DEFAULT_STANDALONE)
      @p12 = OpenSSL::PKCS12.new(File.read("tmp/pruebas.p12"),"8753")
      @x509 = @p12.certificate
      @output_path = output_path
    end
    
    def sign
      #Build parts for Digest Calculation
      key_info = build_key_info_element
      signed_properties = build_signed_properties_element
      signed_info_element = build_signed_info_element(key_info,signed_properties)
      # Compute Signature
      signed_info_canon = canonicalize_document(signed_info_element)
      signature_value = compute_signature(@p12.key,algorithm(RSA_SHA256).new,signed_info_canon)
      
      # delete parts namespaces
      delete_namespaces(signed_info_element)
      delete_namespaces(key_info)
      delete_namespaces(signed_properties)
      
      # Created Signature element and add parts
      signature_element = REXML::Element.new("ds:Signature").add_namespace('ds', DSIG)
      signature_element.add_attribute("Id","xmldsig-#{uuid}")
      
      signature_element.add_element(signed_info_element)
      signature_element.add_element("ds:SignatureValue","Id"=>"xmldsig-#{uuid}-sigvalue").text = signature_value
      signature_element.add_element(key_info)
      
      object = signature_element.add_element("ds:Object")
      qualifying_properties = object.add_element("xades:QualifyingProperties", {"Target"=>"#xmldsig-#{uuid}"})
      qualifying_properties.add_namespace("xades", XADES)
      qualifying_properties.add_namespace("xades141", XADES141)
      
      qualifying_properties.add_element(signed_properties)
      
      @doc.root.add_element(signature_element)
      
      File.open(@output_path,"w"){|f| f.write(@doc.to_s)} if @output_path
      
      @doc
    end
    
    private
    
    def build_signed_properties_element
      cert_digest = compute_digest(@x509.to_der,algorithm(SHA256))
      policy_digest = compute_digest(@x509.to_der,algorithm(SHA256))
      signing_time = DateTime.now
      
      element = REXML::Element.new("xades:SignedProperties",nil,{:attribute_quote=>:quote})
      element.add_namespace("https://tribunet.hacienda.go.cr/docs/esquemas/2017/v4.2/facturaElectronica")
      element.add_namespace("ds","http://www.w3.org/2000/09/xmldsig#")
      element.add_namespace("xades","http://uri.etsi.org/01903/v1.3.2#")
      element.add_namespace("xsd","http://www.w3.org/2001/XMLSchema")
      element.add_namespace("xsi","http://www.w3.org/2001/XMLSchema-instance")
      element.add_namespace("xades141", XADES141)
      element.add_attribute("Id","xmldsig-#{uuid}-signedprops")
  
      element.add_element("xades:SigningTime").text = signing_time.rfc3339
      signing_certificate_elem = element.add_element("xades:SigningCertificate")
      cert_elem = signing_certificate_elem.add_element("xades:Cert")
      cert_digest_elem = cert_elem.add_element("xades:CertDigest")
      cert_digest_elem.add_element("ds:DigestMethod", {"Algorithm"=>SHA256})
      cert_digest_elem.add_element("ds:DigestValue").text = cert_digest

      issuer_serial = cert_elem.add_element("xades:IssuerSerial")
      issuer_serial.add_element("ds:X509IssuerName").text = @x509.issuer.to_a.reverse.map{|c| c[0..1].join("=")}.join(", ")
      issuer_serial.add_element("ds:X509SerialNumber").text = @x509.serial.to_s

      policy_elem = element.add_element("xades:SignaturePolicyIdentifier")
      policy_id_elem = policy_elem.add_element("xades:SignaturePolicyId")
      sig_policy_id = policy_id_elem.add_element("xades:SigPolicyId")
      sig_policy_id.add_element("xades:Identifier").text = SIGNATURE_POLICY

      policy_hash  = sig_policy_id.add_element("xades:SigPolicyHash")
      policy_hash.add_element("ds:DigestMethod", {"Algorithm"=>"http://www.w3.org/2000/09/xmldsig#sha1"})
      policy_hash.add_element("ds:DigestValue").text = "V8lVVNGDCPen6VELRD1Ja8HARFk="#policy_digest
      
      element
    end
    
    def build_key_info_element
      key_info = REXML::Element.new("ds:KeyInfo",nil,{:attribute_quote=>:quote})
      key_info.add_namespace("https://tribunet.hacienda.go.cr/docs/esquemas/2017/v4.2/facturaElectronica")
      key_info.add_namespace("ds","http://www.w3.org/2000/09/xmldsig#")
      key_info.add_namespace("xsd","http://www.w3.org/2001/XMLSchema")
      key_info.add_namespace("xsi","http://www.w3.org/2001/XMLSchema-instance")
  
      key_info.add_attribute("Id","xmldsig-#{uuid}-keyinfo")
      x509_data = key_info.add_element("ds:X509Data")
      x509_data.add_element("ds:X509Certificate").text = @x509.to_pem.to_s.gsub("-----BEGIN CERTIFICATE-----","").gsub("-----END CERTIFICATE-----","").gsub(/\n|\r/, "")
      key_value = key_info.add_element("ds:KeyValue")
      rsa_value = key_value.add_element("ds:RSAKeyValue")
      rsa_value.add_element("ds:Modulus").text = Base64.encode64(@x509.public_key.params["n"].to_s(2)).gsub("\n","")
      rsa_value.add_element("ds:Exponent").text = Base64.encode64(@x509.public_key.params["e"].to_s(2)).gsub("\n","")
      key_info
    end
    
    def build_signed_info_element(key_info_element, signed_props_element)
      
      signed_info_element = REXML::Element.new("ds:SignedInfo",nil,{:attribute_quote=>:quote})
      signed_info_element.add_namespace("https://tribunet.hacienda.go.cr/docs/esquemas/2017/v4.2/facturaElectronica")
      signed_info_element.add_namespace("ds","http://www.w3.org/2000/09/xmldsig#")
      signed_info_element.add_namespace("xsd","http://www.w3.org/2001/XMLSchema")
      signed_info_element.add_namespace("xsi","http://www.w3.org/2001/XMLSchema-instance")
      signed_info_element.add_element("ds:CanonicalizationMethod", { "Algorithm"=>C14N })
      signed_info_element.add_element("ds:SignatureMethod", {"Algorithm"=>RSA_SHA256})
      
      # Add Ref0
      ref0 = signed_info_element.add_element("ds:Reference",{"Id"=>"xmldsig-#{uuid}-ref0"})
      transforms = ref0.add_element("ds:Transforms")
      transform = transforms.add_element("ds:Transform", {"Algorithm"=>ENVELOPED_SIG})
      digest_method_element = ref0.add_element("ds:DigestMethod", {"Algorithm"=> SHA256})
      ref0.add_element("ds:DigestValue").text = digest_document(@doc,SHA256)
      
      # Add KeyInfo Ref
      ref_key_info = signed_info_element.add_element("ds:Reference",{"URI"=>"#xmldsig-#{uuid}-keyinfo"})
      ref_key_info.add_element("ds:DigestMethod", {"Algorithm"=> SHA256})
      ref_key_info.add_element("ds:DigestValue").text = digest_document(key_info_element, SHA256, true)
      
      # Add SignedProps Ref
      ref_props = signed_info_element.add_element("ds:Reference",{"URI"=>"#xmldsig-#{uuid}-signedprops", "Type"=>"http://uri.etsi.org/01903#SignedProperties"})
      ref_props.add_element("ds:DigestMethod", {"Algorithm"=> SHA256})
      ref_props.add_element("ds:DigestValue").text = digest_document(signed_props_element, SHA256,true)
      
      signed_info_element
    end
    
    def digest_document(doc, digest_algorithm=SHA256, strip=false)
      compute_digest(canonicalize_document(doc,strip),algorithm(digest_algorithm))
    end
    
    def canonicalize_document(doc,strip=false)
      doc = doc.to_s if doc.is_a?(REXML::Element)
      doc.strip! if strip
      doc.encode("UTF-8")
      noko = Nokogiri::XML(doc) do |config|
        config.options = NOKOGIRI_OPTIONS
      end
      
      noko.canonicalize(canon_algorithm(C14N),NAMESPACES.split(" "))
    end
    
    def delete_namespaces(element)
      NAMESPACES.split(" ").each do |ns|
        element.delete_namespace(ns)
      end
    end
    
    def uuid
      @uuid ||= SecureRandom.uuid
    end
    
    def canon_algorithm(element)
     algorithm = element
     if algorithm.is_a?(REXML::Element)
       algorithm = element.attribute('Algorithm').value
     end

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
      Base64.encode64(private_key.sign(signature_algorithm, document)).gsub(/\n/, "")
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