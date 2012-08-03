require 'spec_helper'

module Drudgery
  module Extractors
    describe SQLite3Extractor do
      before do
        @db = SQLite3::Database.new(':memory:')
        @db.execute('CREATE TABLE records (a INTEGER, b INTEGER)')
        @db.execute('INSERT INTO records (a, b) VALUES (1, 2)');
        @db.execute('INSERT INTO records (a, b) VALUES (3, 4)');
        @db.execute('INSERT INTO records (a, b) VALUES (3, 6)');
      end

      after do
        @db.close
      end

      let(:extractor) { SQLite3Extractor.new(@db, 'records') }

      describe '#name' do
        describe 'with file based db' do
          it 'returns sqlite3:<main db name>.<table name>' do
            db = SQLite3::Database.new('tmp/test.sqlite3')

            extractor = SQLite3Extractor.new(db, 'people')
            extractor.name.must_equal 'sqlite3:test.people'
          end
        end

        describe 'with in memory db' do
          it 'returns sqlite3:memory.<table name>' do
            extractor = SQLite3Extractor.new(@db, 'cities')
            extractor.name.must_equal 'sqlite3:memory.cities'
          end
        end
      end

      describe '#select' do
        it 'sets select clause with provided expressions' do
          extractor.select('id', "(first_name || ' ' || last_name) AS name", 'email')
          extractor.send(:sql).must_equal "SELECT id, (first_name || ' ' || last_name) AS name, email FROM records"
        end
      end

      describe '#from' do
        it 'sets from clause with provided expression' do
          extractor.from('records AS r')
          extractor.send(:sql).must_equal 'SELECT * FROM records AS r'
        end
      end

      describe '#joins' do
        it 'sets join clauses with provided clauses' do
          joins = [
            'JOIN table2 t2 ON t2.my_id = t1.id',
            'LEFT OUTER JOIN table3 t3 ON t3.my_id = t2.id'
          ]

          extractor.joins(joins[0], joins[1])
          extractor.send(:sql).must_equal 'SELECT * FROM records JOIN table2 t2 ON t2.my_id = t1.id LEFT OUTER JOIN table3 t3 ON t3.my_id = t2.id'
        end
      end

      describe '#group' do
        it 'sets group clause with provided expressions' do
          extractor.group('id', 'email')
          extractor.send(:sql).must_equal 'SELECT * FROM records GROUP BY id, email'
        end
      end

      describe '#where' do
        it 'sets where clause with provided condition' do
          extractor.where('age >= 18 AND age < 50')
          extractor.send(:sql).must_equal 'SELECT * FROM records WHERE age >= 18 AND age < 50'
        end
      end

      describe '#having' do
        it 'sets having clause with provided condition' do
          extractor.having('COUNT(*) > 1')
          extractor.send(:sql).must_equal 'SELECT * FROM records HAVING COUNT(*) > 1'
        end
      end

      describe '#order' do
        it 'sets order clause with provided expressions' do
          extractor.order('id', 'email DESC')
          extractor.send(:sql).must_equal 'SELECT * FROM records ORDER BY id, email DESC'
        end
      end

      describe '#extract' do
        describe 'with custom query' do
          it 'yields each record hash and index' do
            extractor.where('a > 2')

            records = []
            indexes = []
            extractor.extract do |record, index|
              records << record
              indexes << index
            end

            records.must_equal([
              { 'a' => 3, 'b' => 4 },
              { 'a' => 3, 'b' => 6 }
            ])

            indexes.must_equal [0, 1]
          end
        end

        describe 'without custom query' do
          it 'yields each record hash and index' do
            records = []
            indexes = []
            extractor.extract do |record, index|
              records << record
              indexes << index
            end

            records.must_equal([
              { 'a' => 1, 'b' => 2 },
              { 'a' => 3, 'b' => 4 },
              { 'a' => 3, 'b' => 6 }
            ])

            indexes.must_equal [0, 1, 2]
          end
        end
      end

      describe '#record_count' do
        describe 'with custom query' do
          it 'returns count of query results' do
            extractor = SQLite3Extractor.new(@db, 'records')
            extractor.where('a > 2')
            extractor.record_count.must_equal 2
          end
        end

        describe 'without custom query' do
          it 'returns count of table records' do
            extractor = SQLite3Extractor.new(@db, 'records')
            extractor.record_count.must_equal 3
          end
        end
      end
    end
  end
end
