require 'spec_helper'
require 'active_record'

describe Drudgery::Loaders::ActiveRecordLoader do
  class Record < ActiveRecord::Base; end

  def mock_model
    stub('model', :name => 'Record')
  end

  describe '#initialize' do
    it 'sets model to provided argument' do
      model = mock_model

      loader = Drudgery::Loaders::ActiveRecordLoader.new(model)
      loader.instance_variable_get('@model').must_equal model
    end

    it 'sets name to active_record:<model name>' do
      loader = Drudgery::Loaders::ActiveRecordLoader.new(mock_model)
      loader.name.must_equal 'active_record:Record'
    end
  end

  describe '#load' do
    it 'write records using model.create' do
      record1 = { :a => 1 }
      record2 = { :a => 2 }

      obj1 = mock('obj1')
      obj2 = mock('obj2')

      model = mock_model
      model.expects(:new).with(record1).returns(obj1)
      model.expects(:new).with(record2).returns(obj2)

      obj1.expects(:save).with(:validate => false)
      obj2.expects(:save).with(:validate => false)

      loader = Drudgery::Loaders::ActiveRecordLoader.new(model)
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
      it 'writes records using model.create' do
        record1 = { :a => 1, :b => 2 }
        record2 = { :a => 3, :b => 4 }

        loader = Drudgery::Loaders::ActiveRecordLoader.new(Record)
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
