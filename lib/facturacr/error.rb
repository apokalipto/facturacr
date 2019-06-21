module FE
  class Error < StandardError
    attr_reader :messages, :klass
    
    def initialize(msg, args = {})
      @klass = args[:class]
      @messages = args[:messages]
      super(msg)
    end
  end
end