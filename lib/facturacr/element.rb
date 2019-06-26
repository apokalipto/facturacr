module FE
  class Element
    attr_accessor :version, :document
    
    def build_xml(node, document)
      raise "must be implemented in sublcasses"
    end
  end
end