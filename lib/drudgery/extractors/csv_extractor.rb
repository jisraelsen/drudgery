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
    end
  end
end
