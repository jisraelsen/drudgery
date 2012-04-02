module Drudgery
  module Loaders
    class ActiveRecordLoader
      def initialize(model)
        @model = model
      end

      def load(records)
        records.each do |record|
          @model.new(record).save(:validate => false)
        end
      end
    end
  end
end
