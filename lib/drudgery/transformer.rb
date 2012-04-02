module Drudgery
  class Transformer
    def initialize
      @processors = []
      @cache = {}
    end

    def register(processor)
      @processors << processor
    end

    def transform(data)
      symbolize_keys!(data)

      @processors.each do |processor|
        data = processor.call(data, @cache)
        break if data.nil?
      end

      data
    end

    private
    def symbolize_keys!(data)
      data.keys.each do |key|
        data[(key.to_sym rescue key) || key] = data.delete(key)
      end
    end
  end
end
