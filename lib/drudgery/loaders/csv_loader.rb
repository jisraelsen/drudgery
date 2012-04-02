require 'csv'

module Drudgery
  module Loaders
    class CSVLoader
      def initialize(filepath, options={})
        @filepath = filepath
        @options = options

        @write_headers = true
      end

      def load(records)
        columns = records.first.keys.sort { |a,b| a.to_s <=> b.to_s }

        CSV.open(@filepath, 'a', @options) do |csv|
          if @write_headers
            csv << columns
            @write_headers = false
          end

          records.each do |record|
            csv << columns.map { |column| record[column] }
          end
        end
      end
    end
  end
end
