require 'spec_helper'
require 'sqlite3'

describe Drudgery::Extractors::SQLite3Extractor do
  describe '#initialize' do
    it 'sets db and table to provided arguments' do
      db = mock
      db.expects(:results_as_hash=).with(true)
      db.expects(:type_translation=).with(true)

      extractor = Drudgery::Extractors::SQLite3Extractor.new(db, 'tablename')
      extractor.instance_variable_get('@db').must_equal db
      extractor.instance_variable_get('@table').must_equal 'tablename'
    end

    it 'initializes clauses hash' do
      db = mock
      db.stubs(:results_as_hash=)
      db.stubs(:type_translation=)

      extractor = Drudgery::Extractors::SQLite3Extractor.new(db, 'tablename')
      extractor.instance_variable_get('@clauses').must_equal({})
    end
  end

  describe 'query building' do
    before(:each) do
      db = mock
      db.stubs(:results_as_hash=)
      db.stubs(:type_translation=)

      @extractor = Drudgery::Extractors::SQLite3Extractor.new(db, 'tablename')
    end

    describe '#select' do
      it 'sets select clause with provided expressions' do
        @extractor.select('id', "(first_name || ' ' || last_name) AS name", 'email')
        @extractor.instance_variable_get('@clauses').must_equal({ :select => "id, (first_name || ' ' || last_name) AS name, email" })
      end
    end

    describe '#from' do
      it 'sets from clause with provided expression' do
        @extractor.from('table AS t')
        @extractor.instance_variable_get('@clauses').must_equal({ :from => 'table AS t' })
      end
    end

    describe '#joins' do
      it 'sets join clauses with provided clauses' do
        joins = [
          'JOIN table2 t2 ON t2.my_id = t1.id',
          'LEFT OUTER JOIN table3 t3 ON t3.my_id = t2.id'
        ]

        @extractor.joins(joins[0], joins[1])
        @extractor.instance_variable_get('@clauses').must_equal({ :joins => joins })
      end
    end

    describe '#group' do
      it 'sets group clause with provided expressions' do
        @extractor.group('id', 'email')
        @extractor.instance_variable_get('@clauses').must_equal({ :group => 'id, email' })
      end
    end

    describe '#where' do
      it 'sets where clause with provided condition' do
        @extractor.where('age >= 18 AND age < 50')
        @extractor.instance_variable_get('@clauses').must_equal({ :where => 'age >= 18 AND age < 50' })
      end
    end

    describe '#having' do
      it 'sets having clause with provided condition' do
        @extractor.having('count(*) > 1')
        @extractor.instance_variable_get('@clauses').must_equal({ :having => 'count(*) > 1' })
      end
    end

    describe '#order' do
      it 'sets order clause with provided expressions' do
        @extractor.order('id', 'email DESC')
        @extractor.instance_variable_get('@clauses').must_equal({ :order => 'id, email DESC' })
      end
    end
  end

  describe '#extract' do
    it 'selects records from db using defined query' do
      db = mock
      db.stubs(:results_as_hash=)
      db.stubs(:type_translation=)
      db.expects(:execute).with('SELECT * FROM tablename')
      db.expects(:execute).with('SELECT age, count(*) AS nr_ages FROM tablename t table2 t2 ON t2.my_id = t.id WHERE age > 10 GROUP BY age HAVING count(*) > 1 ORDER BY nr_ages')

      extractor = Drudgery::Extractors::SQLite3Extractor.new(db, 'tablename')
      extractor.extract

      extractor.select('age', 'count(*) AS nr_ages')
      extractor.from('tablename t')
      extractor.joins('table2 t2 ON t2.my_id = t.id')
      extractor.where('age > 10')
      extractor.group('age')
      extractor.having('count(*) > 1')
      extractor.order('nr_ages')

      extractor.extract
    end

    it 'yields each record as a hash' do
      record1 = { :a => 1 }
      record2 = { :b => 2 }

      db = mock
      db.stubs(:results_as_hash=)
      db.stubs(:type_translation=)
      db.stubs(:execute).multiple_yields([record1], [record2])

      extractor = Drudgery::Extractors::SQLite3Extractor.new(db, 'tablename')

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
      @db = SQLite3::Database.new(':memory:')
      @db.execute('CREATE TABLE records (a INTEGER, b INTEGER)')
      @db.execute('INSERT INTO records (a, b) VALUES (1, 2)');
      @db.execute('INSERT INTO records (a, b) VALUES (3, 4)');
      @db.execute('INSERT INTO records (a, b) VALUES (3, 6)');
    end

    after(:each) do
      @db.close
    end

    describe '#extract' do
      it 'yields each record as a hash' do
        extractor = Drudgery::Extractors::SQLite3Extractor.new(@db, 'records')

        records = []
        extractor.extract do |record|
          records << record
        end

        records.must_equal([
          { 'a' => 1, 'b' => 2 },
          { 'a' => 3, 'b' => 4 },
          { 'a' => 3, 'b' => 6 }
        ])
      end
    end

    describe '#record_count' do
      describe 'with custom query' do
        it 'returns count of query results' do
          extractor = Drudgery::Extractors::SQLite3Extractor.new(@db, 'records')
          extractor.where('a > 2')
          extractor.group('a')
          extractor.record_count.must_equal 1
        end
      end

      describe 'without custom query' do
        it 'returns count of table records' do
          extractor = Drudgery::Extractors::SQLite3Extractor.new(@db, 'records')
          extractor.record_count.must_equal 3
        end
      end
    end
  end
end
