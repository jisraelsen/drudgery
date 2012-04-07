module Drudgery
  class Job
    attr_reader :id

    def initialize(options={})
      @id           = Time.now.nsec
      @extractor    = options[:extractor]
      @loader       = options[:loader]
      @transformer  = options[:transformer]
      @batch_size   = options[:batch_size] || 1000

      @records = []
    end

    def name
      "#{@extractor.name} => #{@loader.name}"
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
      log_with_progress :info, name

      elapsed = Benchmark.realtime do
        extract_records do |record|
          @records << record

          if @records.size == @batch_size
            load_records
          end

          progress.inc if Drudgery.show_progress
        end

        load_records

        progress.finish if Drudgery.show_progress
      end

      log_with_progress :info, "Completed in #{"%.2f" % elapsed}s\n\n"
    end

    private
    def extract_records
      @extractor.extract do |data, index|
        log :debug, "Extracting Record -- Index: #{index}"
        log :debug, data.inspect

        record = transform_data(data)
        log :debug, "Transforming Record -- Index: #{index}"
        log :debug, data.inspect

        if record.nil?
          next
        else
          yield record
        end
      end
    end

    def load_records
      return if @records.empty?
      log :debug, "Loading Records -- Count: #{@records.size}"
      log :debug, @records.inspect

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

    def progress
      unless @progress
        @progress = ProgressBar.new(log_prefix, @extractor.record_count)
        @progress.title_width = log_prefix.length + 1
      end

      @progress
    end

    def log_prefix
      "## JOB #{id}"
    end

    def format_message(message)
      "#{log_prefix}: #{message}"
    end

    def log_with_progress(mode, message)
      STDERR.puts format_message(message) if Drudgery.show_progress
      log(mode, message)
    end

    def log(mode, message)
      Drudgery.log mode, format_message(message)
    end
  end
end
