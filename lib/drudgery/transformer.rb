module Drudgery
  class Transformer
    def initialize
      @cache = {}
    end

    def register(processor)
      @processor = processor
    end

    def transform(data)
      symbolize_keys!(data)

      @processor ? @processor.call(data, @cache) : data
    end

    private
    def symbolize_keys!(data)
      data.keys.each do |key|
        data[(key.to_sym rescue key) || key] = data.delete(key)
      end
    end
  end
end
