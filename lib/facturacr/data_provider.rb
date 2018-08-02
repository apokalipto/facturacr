module FE
  
  class DataProvider
    SOURCES = [:string, :file]
    
    attr_accessor :contents
    
    def initialize(source, data)
      source = source.to_s.to_sym
      raise ArgumentError, "source (#{source}) is not valid" if !SOURCES.include?(source)
      raise ArgumentError, "#{data} does not exist" if soruce.eql?(:file) && !File.exists?(data)
      
      if source.eql?(:string)
        @contents = data
      elsif source.eql?(:file)
        @contents = File.read(data)
      end
    end   
  end
  
end