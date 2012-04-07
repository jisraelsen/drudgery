module Drudgery
  module Loaders
    class ActiveRecordLoader
      attr_reader :name

      def initialize(model)
        @model = model
        @name = "active_record:#{@model.name}"
      end

      def load(records)
        records.each do |record|
          @model.new(record).save(:validate => false)
        end
      end
    end
  end
end
