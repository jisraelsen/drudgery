require 'spec_helper'
require 'active_record'
require 'activerecord-import'

describe Drudgery::Loaders::ActiveRecordImportLoader do
  class Record < ActiveRecord::Base; end

  def mock_model
    stub('model', :name => 'Record')
  end

  describe '#initialize' do
    it 'sets model to provided argument' do
      model = mock_model

      loader = Drudgery::Loaders::ActiveRecordImportLoader.new(model)
      loader.instance_variable_get('@model').must_equal model
    end

    it 'sets name to active_record_import:<model name>' do
      loader = Drudgery::Loaders::ActiveRecordImportLoader.new(mock_model)
      loader.name.must_equal 'active_record_import:Record'
    end
  end

  describe '#load' do
    it 'write records using model.import' do
      record1 = { :a => 1, :b => 2 }
      record2 = { :a => 3, :b => 4 }

      model = mock_model
      model.expects(:import).with([:a, :b], [[1, 2], [3, 4]], :validate => false)

      loader = Drudgery::Loaders::ActiveRecordImportLoader.new(model)
      loader.load([record1, record2])
    end
  end

  describe 'without stubs' do
    before(:each) do
      ActiveRecord::Base.establish_connection(:adapter => 'sqlite3', :database => ':memory:')
      ActiveRecord::Base.connection.create_table(:records) do |t|
        t.integer :a
        t.integer :b
      end
    end

    after(:each) do
      ActiveRecord::Base.clear_active_connections!
    end

    describe '#load' do
      it 'writes records using model.import' do
        record1 = { :a => 1, :b => 2 }
        record2 = { :a => 3, :b => 4 }

        loader = Drudgery::Loaders::ActiveRecordImportLoader.new(Record)
        loader.load([record1, record2])

        records = Record.all.map(&:attributes)
        records.must_equal([
          { 'id' => 1, 'a' => 1, 'b' => 2 },
          { 'id' => 2, 'a' => 3, 'b' => 4 }
        ])
      end
    end
  end
end
