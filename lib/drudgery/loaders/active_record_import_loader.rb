module Drudgery
  module Loaders
    class ActiveRecordImportLoader
      def initialize(model)
        @model = model
      end

      def load(records)
        columns = records.first.keys
        values = records.map { |record| columns.map { |column| record[column] } }

        @model.import(columns, values, :validate => false)
      end
    end
  end
end
