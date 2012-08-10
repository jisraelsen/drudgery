require 'spec_helper'

module Drudgery
  describe Drudgery do
    before do
      Drudgery.listeners.clear
    end

    after do
      Drudgery.listeners.clear
    end

    describe '.subscribe' do
      it 'subscribes listener for event' do
        block = proc { |job| 1 + 1 }
        Drudgery.subscribe(:before_job, &block)

        Drudgery.listeners[:before_job].must_equal [block]
      end

      it 'supports subscription of multiple listeners for a single event' do
        block1 = proc { |job| 1 + 1 }
        block2 = proc { |job| 2 + 2 }
        Drudgery.subscribe(:before_job, &block1)
        Drudgery.subscribe(:before_job, &block2)

        Drudgery.listeners[:before_job].must_equal [block1, block2]
      end
    end

    describe '.unsubscribe' do
      before do
        block1 = proc { |job| 1 + 1 }
        block2 = proc { |job| 2 + 2 }
        Drudgery.subscribe(:before_job, &block1)
        Drudgery.subscribe(:before_job, &block2)
      end

      it 'unsubscribes all listeners for event' do
        Drudgery.unsubscribe(:before_job)

        Drudgery.listeners[:before_job].must_be_empty
      end
    end

    describe '.notify' do
      it 'notifies all listeners with given arguments for event' do
        Drudgery.subscribe(:before_job) { |r| r[:x] = 1 + 1 }

        result = {}

        Drudgery.notify(:before_job, result)

        result[:x].must_equal 2
      end
    end
  end

  describe Extractors do
    describe '.instantiate' do
      it 'initializes extractor of type with args' do
        Extractors::CSVExtractor.expects(:new).with('file.csv', :col_sep => '|')
        Extractors.instantiate(:csv, 'file.csv', :col_sep => '|')

        Extractors::SQLite3Extractor.expects(:new).with('db.sqlite3', 'tablename')
        Extractors.instantiate(:sqlite3, 'db.sqlite3', 'tablename')

        model = stub('model')
        Extractors::ActiveRecordExtractor.expects(:new).with(model)
        Extractors.instantiate(:active_record, model)
      end

      it 'returns an extractor' do
        extractor = Extractors.instantiate(:csv, 'file.csv')
        extractor.must_be_kind_of Extractors::CSVExtractor
      end
    end
  end

  describe Loaders do
    describe '.instantiate' do
      it 'initializes loader of type with args' do
        Loaders::CSVLoader.expects(:new).with('file.csv', :col_sep => '|')
        Loaders.instantiate(:csv, 'file.csv', :col_sep => '|')

        Loaders::SQLite3Loader.expects(:new).with('db.sqlite3', 'tablename')
        Loaders.instantiate(:sqlite3, 'db.sqlite3', 'tablename')

        model = stub('model')
        Loaders::ActiveRecordLoader.expects(:new).with(model)
        Loaders.instantiate(:active_record, model)

        Loaders::ActiveRecordImportLoader.expects(:new).with(model)
        Loaders.instantiate(:active_record_import, model)
      end

      it 'returns an loader' do
        loader = Loaders.instantiate(:csv, 'file.csv')
        loader.must_be_kind_of Loaders::CSVLoader
      end
    end
  end
end
