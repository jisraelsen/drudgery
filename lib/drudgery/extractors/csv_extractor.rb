require 'csv'

module Drudgery
  module Extractors
    class CSVExtractor
      def initialize(filepath, options={})
        @filepath = filepath
        @options = { :headers => true }
        @options.merge!(options)
      end

      def extract
        CSV.foreach(@filepath, @options) do |row|
          yield row.to_hash
        end
      end

      def record_count
        @record_count ||= calculate_record_count
      end

      private
      def calculate_record_count
        record_count = 0

        extract do |row|
          record_count += 1
        end

        record_count
      end
    end
  end
end
