module Drudgery
  class Job
    def initialize(options={})
      @extractor    = options[:extractor]
      @loader       = options[:loader]
      @transformer  = options[:transformer] || Drudgery::Transformer.new

      @batch_size, @records = 1000, []
    end

    def batch_size(size)
      @batch_size = size
    end

    def extract(type, *args)
      extractor = Drudgery::Extractors.instantiate(type, *args)

      yield extractor if block_given?

      @extractor = extractor
    end

    def transform(&processor)
      @transformer.register(processor)
    end

    def load(type, *args)
      loader = Drudgery::Loaders.instantiate(type, *args)

      yield loader if block_given?

      @loader = loader
    end

    def perform
      extract_records do |record|
        @records << record

        if @records.size == @batch_size
          load_records
        end
      end

      load_records
    end

    private
    def extract_records
      @extractor.extract do |data|
        record = @transformer.transform(data)
        next if record.nil?

        yield record
      end
    end

    def load_records
      @loader.load(@records)
      @records.clear
    end
  end
end
