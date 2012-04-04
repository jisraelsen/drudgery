module Drudgery
  class Job
    def initialize(options={})
      @extractor    = options[:extractor]
      @loader       = options[:loader]
      @transformer  = options[:transformer]
      @batch_size   = options[:batch_size] || 1000

      @records = []
    end

    def batch_size(size)
      @batch_size = size
    end

    def extract(*args)
      if args.first.kind_of?(Symbol)
        extractor = Drudgery::Extractors.instantiate(*args)
      else
        extractor = args.first
      end

      yield extractor if block_given?

      @extractor = extractor
    end

    def transform(transformer=Drudgery::Transformer.new, &processor)
      transformer.register(processor)

      @transformer = transformer
    end

    def load(*args)
      if args.first.kind_of?(Symbol)
        loader = Drudgery::Loaders.instantiate(*args)
      else
        loader = args.first
      end

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
        record = transform_data(data)
        next if record.nil?

        yield record
      end
    end

    def load_records
      @loader.load(@records)
      @records.clear
    end

    def transform_data(data)
      if @transformer
        @transformer.transform(data)
      else
        data
      end
    end
  end
end
