require 'spec_helper'

module Drudgery
  module Loaders
    describe SQLite3Loader do
      before do
        @db = SQLite3::Database.new(':memory:')
        @db.execute('CREATE TABLE records (a INTEGER, b INTEGER)')
      end

      after do
        @db.close
      end

      describe '#name' do
        describe 'with file based db' do
          it 'returns sqlite3:<main db name>:<table name>' do
            db = SQLite3::Database.new('tmp/test.sqlite3')

            loader = SQLite3Loader.new(db, 'people')
            loader.name.must_equal 'sqlite3:test.people'
          end
        end

        describe 'with in memory db' do
          it 'returns sqlite3:memory:<table name>' do
            loader = SQLite3Loader.new(@db, 'cities')
            loader.name.must_equal 'sqlite3:memory.cities'
          end
        end
      end

      describe '#load' do
        it 'writes each record in single transaction' do
          record1 = { :a => 1, :b => 2 }
          record2 = { :a => 3, :b => 4 }

          loader = SQLite3Loader.new(@db, 'records')
          loader.load([record1, record2])

          results = []
          @db.execute('SELECT * FROM records') do |result|
            result.reject! { |key, value| key.kind_of?(Integer) }
            results << result
          end

          results.must_equal([
            { 'a' => 1, 'b' => 2 },
            { 'a' => 3, 'b' => 4 }
          ])
        end
      end
    end
  end
end
