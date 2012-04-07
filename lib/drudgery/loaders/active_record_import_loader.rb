module Drudgery
  module Loaders
    class ActiveRecordImportLoader
      attr_reader :name

      def initialize(model)
        @model = model
        @name = "active_record_import:#{@model.name}"
      end

      def load(records)
        columns = records.first.keys
        values = records.map { |record| columns.map { |column| record[column] } }

        @model.import(columns, values, :validate => false)
      end
    end
  end
end
