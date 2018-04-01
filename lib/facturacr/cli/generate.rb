require 'active_support/core_ext/hash/indifferent_access'
module FE
  class CLI < Thor
    class Generate < Thor
    
      desc "invoice", "generates an XML invoice"
      method_option :config_file, aliases: '-c', desc: "default configuration file", default: "tmp/config.yml"
      method_option :number, aliases: '-n', desc: "set the number of the document"
      method_option :sign, type: :boolean, default: false
      method_option :send, type: :boolean, default: false
      method_option :data_path, default: "tmp/data.yml"
      method_option :output_path, desc: "path to save the output"     
      def invoice
        data = YAML.load_file(options[:data_path]).with_indifferent_access
        builder = FE::Builder.new
        
        invoice = builder.invoice(data[:document])
        invoice.date = Time.now
        invoice.number = options[:number].to_i if options[:number].present?
        
        if options[:output_path]
          output_path = output_path
        else
          output_path = "tmp/#{invoice.key}.xml"
        end
        
        write(invoice, output_path)
        print_details(invoice)
        sign(output_path, options) if options[:sign]
        send_document("#{output_path}.signed.xml") if options[:sign] && options[:send]
        
      end
      
      
      desc "credit_note", "generates an XML credit note"
      method_option :config_file, aliases: '-c', desc: "default configuration file", default: "tmp/config.yml"
      method_option :number, aliases: '-n', desc: "set the number of the document"
      method_option :sign, type: :boolean, default: false
      method_option :send, type: :boolean, default: false
      method_option :data_path, default: "tmp/data.yml"
      method_option :output_path, desc: "path to save the output"
      method_option :invoice_number, desc: "invoice key", aliases: "-i"
      method_option :invoice_date, desc: "invoice date", aliases: '-d'
      def credit_note
        data = YAML.load_file(options[:data_path]).with_indifferent_access
        builder = FE::Builder.new
        
        credit_note = builder.credit_note(data[:document])
        if options[:invoice_number].present?
          date = DateTime.parse(options[:invoice_date])
          credit_note.references = [FE::Document::Reference.new(document_type: "01", code: "01", reason: "Anula documento", number: options[:invoice_number], date: date)]
        end
        
        credit_note.date = Time.now
        credit_note.number = options[:number].to_i if options[:number].present?
        
        if options[:output_path]
          output_path = output_path
        else
          output_path = "tmp/#{credit_note.key}.xml"
        end
        
        write(credit_note, output_path)
        print_details(credit_note)
        sign(output_path, options) if options[:sign]
        send_document("#{output_path}.signed.xml") if options[:sign] && options[:send]
        
      end
      
      desc "debit_note", "generates an XML debit note"
      method_option :config_file, aliases: '-c', desc: "default configuration file", default: "tmp/config.yml"
      method_option :number, aliases: '-n', desc: "set the number of the document"
      method_option :sign, type: :boolean, default: false
      method_option :send, type: :boolean, default: false
      method_option :data_path, default: "tmp/data.yml"
      method_option :output_path, desc: "path to save the output"
      method_option :invoice_number, desc: "invoice key", aliases: "-i"
      method_option :invoice_date, desc: "invoice date", aliases: '-d'
      def debit_note
        data = YAML.load_file(options[:data_path]).with_indifferent_access
        builder = FE::Builder.new
        
        debit_note = builder.debit_note(data[:document])
        if options[:invoice_number].present?
          date = DateTime.parse(options[:invoice_date])
          debit_note.references = [FE::Document::Reference.new(document_type: "01", code: "01", reason: "Anula documento", number: options[:invoice_number], date: date)]
        end
        
        debit_note.date = Time.now
        debit_note.number = options[:number].to_i if options[:number].present?
        
        if options[:output_path]
          output_path = output_path
        else
          output_path = "tmp/#{debit_note.key}.xml"
        end
        
        write(debit_note, output_path)
        print_details(debit_note)
        sign(output_path, options) if options[:sign]
        send_document("#{output_path}.signed.xml") if options[:sign] && options[:send]
        
      end
      
      no_commands{
        def write(document, output_path)
          File.open(output_path, 'w'){|f| f.write(document.generate.gsub("\n",""))}
        end
      
        def print_details(document)
          puts "Details:"
          puts "ISSUER: #{FE::Document::IdentificationDocument::TYPES[document.issuer.identification_document.document_type]} #{document.issuer.identification_document.raw_id_number} - #{document.issuer.name}"
          puts "RECEIVER: #{FE::Document::IdentificationDocument::TYPES[document.receiver.identification_document.document_type]} #{document.receiver.identification_document.raw_id_number} - #{document.receiver.name}"
          puts "KEY: #{document.key}"
        end
      
        def sign(path, options)
          puts " => SIGN ..............."
          cli = FE::CLI.new
          cli.options = {config_file: options[:config_file]}
          cli.sign_document("#{path}", "#{path}.signed.xml")
        end
      
        def send_document(path)
          puts "=> SEND TO API ................."
          cli = FE::CLI.new
          cli.options = {config_file: options[:config_file]}
          cli.send_document(path)
        end
      }
    end
  end
end