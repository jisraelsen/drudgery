require 'spec_helper'

describe Drudgery::Loaders::SQLite3Loader do
  describe '#initialize' do
    it 'sets db to SQLite3 database using provided db name and table to provided table name' do
      db = mock

      loader = Drudgery::Loaders::SQLite3Loader.new(db, 'tablename')
      loader.instance_variable_get('@db').must_equal db
      loader.instance_variable_get('@table').must_equal 'tablename'
    end
  end

  describe '#load' do
    it 'writes each record in single transaction' do
      record1 = { :a => 1, :b => 2 }
      record2 = { :a => 3, :b => 4 }

      db = mock
      db.expects(:transaction).yields(db)
      db.expects(:execute).with('INSERT INTO tablename (a, b) VALUES (?, ?)', [1, 2])
      db.expects(:execute).with('INSERT INTO tablename (a, b) VALUES (?, ?)', [3, 4])

      loader = Drudgery::Loaders::SQLite3Loader.new(db, 'tablename')
      loader.load([record1, record2])
    end

    describe 'without stubs' do
      before(:each) do
        @db = SQLite3::Database.new(':memory:')
        @db.execute('CREATE TABLE records (a INTEGER, b INTEGER)')
      end

      after(:each) do
        @db.close
      end

      it 'writes each record in single transaction' do
        record1 = { :a => 1, :b => 2 }
        record2 = { :a => 3, :b => 4 }

        loader = Drudgery::Loaders::SQLite3Loader.new(@db, 'records')
        loader.load([record1, record2])

        results = []
        @db.execute('SELECT * FROM records') do |result|
          results << result
        end

        results.must_equal([
          [1, 2],
          [3, 4]
        ])
      end
    end
  end
end
