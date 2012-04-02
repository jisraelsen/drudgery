module Drudgery
  module Extractors
    class ActiveRecordExtractor
      def initialize(model)
        @model = model
      end

      def extract
        @model.find_each do |record|
          yield record.attributes
        end
      end
    end
  end
end
