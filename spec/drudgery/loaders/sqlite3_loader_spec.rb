require 'spec_helper'
require 'sqlite3'

describe Drudgery::Loaders::SQLite3Loader do

  def mock_db
    stub('db', :database_list => [{ 'name' => 'main', 'file' => '' }], :results_as_hash= => nil, :type_translation= => nil)
  end

  describe '#initialize' do
    it 'sets db to SQLite3 database using provided db name and table to provided table name' do
      db = mock_db

      loader = Drudgery::Loaders::SQLite3Loader.new(db, 'tablename')
      loader.instance_variable_get('@db').must_equal db
      loader.instance_variable_get('@table').must_equal 'tablename'
    end

    describe 'with in memory db' do
      it 'sets name to sqlite3:memory:<table name>' do
        loader = Drudgery::Loaders::SQLite3Loader.new(mock_db, 'tablename')
        loader.name.must_equal 'sqlite3:memory.tablename'
      end
    end

    describe 'with file based db' do
      it 'sets name to sqlite3:<main db name>:<table name>' do
        db = mock_db
        db.expects(:database_list).returns([{ 'name' => 'main', 'file' => 'db/test.sqlite3.db' }])

        loader = Drudgery::Loaders::SQLite3Loader.new(db, 'tablename')
        loader.name.must_equal 'sqlite3:test.tablename'
      end
    end
  end

  describe '#load' do
    it 'writes each record in single transaction' do
      record1 = { :a => 1, :b => 2 }
      record2 = { :a => 3, :b => 4 }

      db = mock_db
      db.expects(:transaction).yields(db)
      db.expects(:execute).with('INSERT INTO tablename (a, b) VALUES (?, ?)', [1, 2])
      db.expects(:execute).with('INSERT INTO tablename (a, b) VALUES (?, ?)', [3, 4])

      loader = Drudgery::Loaders::SQLite3Loader.new(db, 'tablename')
      loader.load([record1, record2])
    end
  end

  describe 'without stubs' do
    before(:each) do
      @db = SQLite3::Database.new(':memory:')
      @db.execute('CREATE TABLE records (a INTEGER, b INTEGER)')
    end

    after(:each) do
      @db.close
    end

    describe '#initialize' do
      it 'sets name to sqlite3:memory:records' do
        loader = Drudgery::Loaders::SQLite3Loader.new(@db, 'records')
        loader.name.must_equal 'sqlite3:memory.records'
      end
    end

    describe '#load' do
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
          { 'a' => 1, 'b' => 2, 0 => 1, 1 => 2 },
          { 'a' => 3, 'b' => 4, 0 => 3, 1 => 4}
        ])
      end
    end
  end
end
