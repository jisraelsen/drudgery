require 'spec_helper'
require 'active_record'

describe Drudgery::Extractors::ActiveRecordExtractor do
  class Record < ActiveRecord::Base; end

  describe '#initialize' do
    it 'sets model to provided argument' do
      model = mock

      extractor = Drudgery::Extractors::ActiveRecordExtractor.new(model)
      extractor.instance_variable_get('@model').must_equal model
    end
  end

  describe '#extract' do
    it 'finds records using model' do
      model = mock
      model.expects(:find_each)

      extractor = Drudgery::Extractors::ActiveRecordExtractor.new(model)
      extractor.extract
    end

    it 'yields each record as a hash' do
      record1 = mock
      record1.expects(:attributes).returns({ :a => 1 })

      record2 = mock
      record2.expects(:attributes).returns({ :b => 2 })

      model = mock
      model.stubs(:find_each).multiple_yields([record1], [record2])

      extractor = Drudgery::Extractors::ActiveRecordExtractor.new(model)

      records = []
      extractor.extract do |record|
        records << record
      end

      records[0].must_equal({ :a => 1 })
      records[1].must_equal({ :b => 2 })
    end

  end

  describe 'without stubs' do
    before(:each) do
      ActiveRecord::Base.establish_connection(:adapter => 'sqlite3', :database => ':memory:')
      ActiveRecord::Base.connection.create_table(:records) do |t|
        t.integer :a
        t.integer :b
      end

      Record.create!({ :a => 1, :b => 2 })
      Record.create!({ :a => 3, :b => 4 })
      Record.create!({ :a => 5, :b => 6 })
    end

    after(:each) do
      ActiveRecord::Base.clear_active_connections!
    end

    describe '#extract' do
      it 'yields each record as a hash' do
        extractor = Drudgery::Extractors::ActiveRecordExtractor.new(Record)

        records = []
        extractor.extract do |record|
          records << record
        end

        records.must_equal([
          { 'id' => 1, 'a' => 1, 'b' => 2 },
          { 'id' => 2, 'a' => 3, 'b' => 4 },
          { 'id' => 3, 'a' => 5, 'b' => 6 }
        ])
      end
    end

    describe '#record_count' do
      it 'returns model count' do
        extractor = Drudgery::Extractors::ActiveRecordExtractor.new(Record)
        extractor.record_count.must_equal 3
      end
    end
  end
end
