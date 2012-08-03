require 'spec_helper'

module Drudgery
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
