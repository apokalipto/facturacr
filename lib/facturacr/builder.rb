require 'facturacr/document'

module FE
  class Builder
    
    def id_document(args = {})
      FE::Document::IdentificationDocument.new type: args[:type], number: args[:number]
    end
  
    def location(args = {})
      FE::Document::Location.new province: args[:province],county: args[:county], district: args[:district], others: args[:others]
    end
  
    def phone(args = {})
      args.reverse_merge!({
        country_code: "506"
      })
      FE::Document::Phone.new country_code: args[:country_code], number: args[:number]
    end
  
    def fax(args = {})
      args.reverse_merge!({
        country_code: "506"
      })
      
      FE::Document::Fax.new country_code: args[:country_code], number: args[:number]
    end
  
    def issuer(args = {})
      if args[:identification_document].is_a?(Hash)
        id_document = self.id_document(args[:identification_document])
      else
        id_document = args[:id_document]
      end
      
      if args[:location].is_a?(Hash)
        location = self.location(args[:location])
      else
        location = args[:location]
      end
      
      if args[:phone].is_a?(Hash)
        phone = self.phone(args[:phone])
      else
        phone = args[:phone]
      end
      
      if args[:fax].is_a?(Hash)
        fax = self.fax(args[:fax])
      else
        fax = args[:fax]
      end
      
      FE::Document::Issuer.new name: args[:name], identification_document: id_document, location: location, phone: phone, fax: fax, email: args[:email]
    end
  
    def receiver(args={})
      if args[:identification_document].is_a?(Hash)
        id_document = self.id_document(args[:identification_document])
      else
        id_document = args[:id_document]
      end
      
      if args[:location].is_a?(Hash)
        location = self.location(args[:location])
      else
        location = args[:location]
      end
      
      if args[:phone].is_a?(Hash)
        phone = self.phone(args[:phone])
      else
        phone = args[:phone]
      end
      
      if args[:fax].is_a?(Hash)
        fax = self.fax(args[:fax])
      else
        fax = args[:fax]
      end
      
      FE::Document::Receiver.new name: args[:name], identification_document: id_document, location: location, phone: phone, fax: fax, email: args[:email]
      
    end
    
    def summary(args={})
      FE::Document::Summary.new args
    end
    
    def item(args={})
      txs = args.delete(:taxes)
      taxes = []
      if txs.is_a?(Array) && txs.first.is_a?(Hash)
        txs.each do |t|
          exo = t.delete(:exoneration)
          if exo && exo.is_a?(Hash)
            t[:exoneration] = FE::Document::Exoneration.new(exo)
          end
          
          taxes << FE::Document::Tax.new(t)
        end
      else
        taxes = txs
      end
      args[:taxes] = taxes
      FE::Document::Item.new(args)
    end
    
    def invoice(args = {})
      if args[:issuer].is_a?(Hash)
        issuer = self.issuer(args[:issuer])
      else
        issuer = args[:issuer]
      end
      
      if args[:receiver].is_a?(Hash)
        receiver = self.receiver(args[:receiver])
      else
        receiver = args[:receiver]
      end
      
      if args[:items].is_a?(Array) && args[:items].first.is_a?(Hash)
        tmp_items = []
        args[:items].each do |i|
          tmp_items << self.item(i)
        end
        items = tmp_items
      else
        items = args[:items]
      end
      
      if args[:summary].is_a?(Hash)
        summary = self.summary(args[:summary])
      else
        summary = args[:summary]
      end
      FE::Invoice.new date: args[:date], issuer: issuer, receiver: receiver, number: args[:number], items: items, condition: args[:condition], credit_term: args[:credit_term], summary: summary, security_code: args[:security_code], document_situation: args[:document_situation]
    end
    
    def ticket(args = {})
      if args[:issuer].is_a?(Hash)
        issuer = self.issuer(args[:issuer])
      else
        issuer = args[:issuer]
      end
      
      if args[:receiver].is_a?(Hash)
        receiver = self.receiver(args[:receiver])
      else
        receiver = args[:receiver]
      end
      
      if args[:items].is_a?(Array) && args[:items].first.is_a?(Hash)
        tmp_items = []
        args[:items].each do |i|
          tmp_items << self.item(i)
        end
        items = tmp_items
      else
        items = args[:items]
      end
      
      if args[:summary].is_a?(Hash)
        summary = self.summary(args[:summary])
      else
        summary = args[:summary]
      end
      FE::Ticket.new date: args[:date], issuer: issuer, receiver: receiver, number: args[:number], items: items, condition: args[:condition], credit_term: args[:credit_term], summary: summary, security_code: args[:security_code], document_situation: args[:document_situation]
    end
    
    
    def credit_note(args = {})
      if args[:issuer].is_a?(Hash)
        issuer = self.issuer(args[:issuer])
      else
        issuer = args[:issuer]
      end
      
      if args[:receiver].is_a?(Hash)
        receiver = self.receiver(args[:receiver])
      else
        receiver = args[:receiver]
      end
      
      if args[:items].is_a?(Array) && args[:items].first.is_a?(Hash)
        tmp_items = []
        args[:items].each do |i|
          tmp_items << self.item(i)
        end
        items = tmp_items
      else
        items = args[:items]
      end
      
      if args[:summary].is_a?(Hash)
        summary = self.summary(args[:summary])
      else
        summary = args[:summary]
      end
      
      if args[:references].is_a?(Array) && args[:references].first.is_a?(Hash)
        references = []
        args[:references].each do |r|
          references << self.reference(r)
        end
      else
        references = args[:references]
      end
      
      FE::CreditNote.new date: args[:date], issuer: issuer, receiver: receiver, number: args[:number], items: items, condition: args[:condition], credit_term: args[:credit_term], summary: summary, security_code: args[:security_code], document_situation: args[:document_situation], references: references
    end
    
    def debit_note(args = {})
      if args[:issuer].is_a?(Hash)
        issuer = self.issuer(args[:issuer])
      else
        issuer = args[:issuer]
      end
      
      if args[:receiver].is_a?(Hash)
        receiver = self.receiver(args[:receiver])
      else
        receiver = args[:receiver]
      end
      
      if args[:items].is_a?(Array) && args[:items].first.is_a?(Hash)
        tmp_items = []
        args[:items].each do |i|
          tmp_items << self.item(i)
        end
        items = tmp_items
      else
        items = args[:items]
      end
      
      if args[:summary].is_a?(Hash)
        summary = self.summary(args[:summary])
      else
        summary = args[:summary]
      end
      
      if args[:references].is_a?(Array) && args[:references].first.is_a?(Hash)
        references = []
        args[:references].each do |r|
          references << self.reference(r)
        end
      else
        references = args[:references]
      end
      
      FE::DebitNote.new date: args[:date], issuer: issuer, receiver: receiver, number: args[:number], items: items, condition: args[:condition], credit_term: args[:credit_term], summary: summary, security_code: args[:security_code], document_situation: args[:document_situation], references: references
    end
    
    def reception_message(args={})
      FE::ReceptionMessage.new number: args[:number], date: args[:date], key: args[:key], 
            issuer_id_number: args[:issuer_id_number], issuer_id_type: args[:issuer_id_type], 
            receiver_id_number: args[:receiver_id_number], receiver_id_type: args[:receiver_id_type], 
            message: args[:message], details: args[:details], tax: args[:tax], total: args[:total], security_code: args[:security_code], document_situation: args[:document_situation]
    end
    
    
    def reference(args={})
      FE::Document::Reference.new args
    end
    
    
  end
end