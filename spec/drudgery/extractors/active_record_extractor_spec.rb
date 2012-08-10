require 'spec_helper'

class Record < ActiveRecord::Base; end

module Drudgery
  module Extractors
    describe ActiveRecordExtractor do
      before do
        ActiveRecord::Base.establish_connection(:adapter => 'sqlite3', :database => ':memory:')
        ActiveRecord::Base.connection.create_table(:records) do |t|
          t.integer :a
          t.integer :b
        end

        Record.create!({ :a => 1, :b => 2 })
        Record.create!({ :a => 3, :b => 4 })
        Record.create!({ :a => 5, :b => 6 })

        @extractor = ActiveRecordExtractor.new(Record)
      end

      after do
        ActiveRecord::Base.clear_active_connections!
      end


      describe '#name' do
        it 'returns active_record:<model name>' do
          @extractor.name.must_equal 'active_record:Record'
        end
      end

      describe '#extract' do
        it 'yields each record hash and index' do
          records, indexes = [], []

          @extractor.extract do |record, index|
            records << record
            indexes << index
          end

          records.must_equal([
            { 'id' => 1, 'a' => 1, 'b' => 2 },
            { 'id' => 2, 'a' => 3, 'b' => 4 },
            { 'id' => 3, 'a' => 5, 'b' => 6 }
          ])

          indexes.must_equal [0, 1, 2]
        end
      end

      describe '#record_count' do
        it 'returns model count' do
          @extractor = ActiveRecordExtractor.new(Record)
          @extractor.record_count.must_equal 3
        end
      end
    end
  end
end
