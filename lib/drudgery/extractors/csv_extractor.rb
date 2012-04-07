module Drudgery
  module Extractors
    class CSVExtractor
      attr_reader :name

      def initialize(filepath, options={})
        @filepath = filepath
        @options = { :headers => true }.merge(options)

        @name = "csv:#{File.basename(@filepath)}"
      end

      def extract
        index = 0

        CSV.foreach(@filepath, @options) do |row|
          yield [row.to_hash, index]

          index += 1
        end
      end

      def record_count
        @record_count ||= calculate_record_count
      end

      private
      def calculate_record_count
        record_count = 0

        extract do |data, index|
          record_count += 1
        end

        record_count
      end
    end
  end
end
