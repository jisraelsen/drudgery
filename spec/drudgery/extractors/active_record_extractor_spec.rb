require 'spec_helper'
require 'active_record'

describe Drudgery::Extractors::ActiveRecordExtractor do
  class Record < ActiveRecord::Base; end

  def mock_model
    stub('model', :name => 'Record')
  end

  describe '#initialize' do
    it 'sets model to provided argument' do
      model = mock_model

      extractor = Drudgery::Extractors::ActiveRecordExtractor.new(model)
      extractor.instance_variable_get('@model').must_equal model
    end

    it 'sets name to active_record:<model name>' do
      extractor = Drudgery::Extractors::ActiveRecordExtractor.new(mock_model)
      extractor.name.must_equal 'active_record:Record'
    end
  end

  describe '#extract' do
    it 'finds records using model' do
      model = mock_model
      model.expects(:find_each)

      extractor = Drudgery::Extractors::ActiveRecordExtractor.new(model)
      extractor.extract
    end

    it 'yields each record hash and index' do
      record1 = mock('record1', :attributes => { :a => 1 })
      record2 = mock('record2', :attributes => { :b => 2 })

      model = mock_model
      model.stubs(:find_each).multiple_yields([record1], [record2])

      extractor = Drudgery::Extractors::ActiveRecordExtractor.new(model)

      records = []
      indexes = []
      extractor.extract do |record, index|
        records << record
        indexes << index
      end

      records[0].must_equal({ :a => 1 })
      records[1].must_equal({ :b => 2 })

      indexes.must_equal [0, 1]
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
      it 'yields each record hash and index' do
        extractor = Drudgery::Extractors::ActiveRecordExtractor.new(Record)

        records = []
        indexes = []
        extractor.extract do |record, index|
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
        extractor = Drudgery::Extractors::ActiveRecordExtractor.new(Record)
        extractor.record_count.must_equal 3
      end
    end
  end
end
