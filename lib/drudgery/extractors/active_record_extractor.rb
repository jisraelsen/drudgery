module Drudgery
  module Extractors
    class ActiveRecordExtractor
      attr_reader :name

      def initialize(model)
        @model = model
        @name = "active_record:#{@model.name}"
      end

      def extract
        index = 0

        @model.find_each do |record|
          yield [record.attributes, index]

          index += 1
        end
      end

      def record_count
        @record_count ||= @model.count
      end
    end
  end
end
