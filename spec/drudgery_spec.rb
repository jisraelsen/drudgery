require 'spec_helper'

describe Drudgery do
  describe '.log' do
    after(:each) do
      Drudgery.logger = nil
    end

    describe 'if logger defined' do
      it 'sends mode and message to logger' do
        logger = mock('logger')
        logger.expects(:send).with(:debug, "Some message")
        Drudgery.logger = logger

        Drudgery.log :debug, "Some message"
      end
    end

    describe 'if no logger defined' do
      it 'ignores mode and message' do
        logger = mock('logger')
        logger.expects(:send).never
        Drudgery.logger = nil

        Drudgery.log :debug, "Some message"
      end
    end
  end
end

describe Drudgery::Extractors do
  describe '.instantiate' do
    it 'initializes extractor of type with args' do
      Drudgery::Extractors::CSVExtractor.expects(:new).with('file.csv', :col_sep => '|')
      Drudgery::Extractors.instantiate(:csv, 'file.csv', :col_sep => '|')

      Drudgery::Extractors::SQLite3Extractor.expects(:new).with('db.sqlite3', 'tablename')
      Drudgery::Extractors.instantiate(:sqlite3, 'db.sqlite3', 'tablename')

      model = stub('model')
      Drudgery::Extractors::ActiveRecordExtractor.expects(:new).with(model)
      Drudgery::Extractors.instantiate(:active_record, model)
    end

    it 'returns an extractor' do
      extractor = Drudgery::Extractors.instantiate(:csv, 'file.csv')
      extractor.must_be_kind_of Drudgery::Extractors::CSVExtractor
    end
  end
end

describe Drudgery::Loaders do
  describe '.instantiate' do
    it 'initializes loader of type with args' do
      Drudgery::Loaders::CSVLoader.expects(:new).with('file.csv', :col_sep => '|')
      Drudgery::Loaders.instantiate(:csv, 'file.csv', :col_sep => '|')

      Drudgery::Loaders::SQLite3Loader.expects(:new).with('db.sqlite3', 'tablename')
      Drudgery::Loaders.instantiate(:sqlite3, 'db.sqlite3', 'tablename')

      model = stub('model')
      Drudgery::Loaders::ActiveRecordLoader.expects(:new).with(model)
      Drudgery::Loaders.instantiate(:active_record, model)

      Drudgery::Loaders::ActiveRecordImportLoader.expects(:new).with(model)
      Drudgery::Loaders.instantiate(:active_record_import, model)
    end

    it 'returns an loader' do
      loader = Drudgery::Loaders.instantiate(:csv, 'file.csv')
      loader.must_be_kind_of Drudgery::Loaders::CSVLoader
    end
  end
end
