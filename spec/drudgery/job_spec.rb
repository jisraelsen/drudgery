require 'spec_helper'

describe Drudgery::Job do
  describe '#initialize' do
    before(:each) do
      @extractor = mock
      @transformer = mock
      @loader = mock

      @job = Drudgery::Job.new(:extractor => @extractor, :transformer => @transformer, :loader => @loader)
    end

    it 'sets extractor, transformer, and loader with provided arguments' do
      @job.instance_variable_get('@extractor').must_equal @extractor
      @job.instance_variable_get('@transformer').must_equal @transformer
      @job.instance_variable_get('@loader').must_equal @loader
    end

    it 'sets batch_size with provided argument' do
      job = Drudgery::Job.new(:batch_size => 100)
      job.instance_variable_get('@batch_size').must_equal(100)
    end

    it 'initializes extractor, transformer, and loader if none provided' do
      job = Drudgery::Job.new
      job.instance_variable_get('@extractor').must_be_nil
      job.instance_variable_get('@transformer').must_be_nil
      job.instance_variable_get('@loader').must_be_nil
    end

    it 'initializes records as array' do
      @job.instance_variable_get('@records').must_equal []
    end


    it 'initializes batch_size as 1000 if none provided' do
      @job.instance_variable_get('@batch_size').must_equal 1000
    end
  end

  describe '#batch_size' do
    it 'sets batch_size to provided value' do
      job = Drudgery::Job.new
      job.batch_size 2
      job.instance_variable_get('@batch_size').must_equal 2
    end
  end

  describe '#extract' do
    describe 'when type and args provided' do
      it 'instantiates extractor with type and args' do
        Drudgery::Extractors.expects(:instantiate).with(:csv, 'filename.csv', :col_sep => '|')

        job = Drudgery::Job.new
        job.extract(:csv, 'filename.csv', :col_sep => '|')
      end

      it 'yields extractor if block_given' do
        extractor = mock
        extractor.expects(:col_sep).with('|')

        Drudgery::Extractors.stubs(:instantiate).returns(extractor)

        job = Drudgery::Job.new
        job.extract(:csv, 'filename.csv') do |extractor|
          extractor.col_sep '|'
        end
      end

      it 'sets extractor' do
        extractor = mock

        Drudgery::Extractors.stubs(:instantiate).returns(extractor)

        job = Drudgery::Job.new
        job.extract(:csv, 'filename.csv', :col_sep => '|')

        job.instance_variable_get('@extractor').must_equal extractor
      end
    end

    describe 'when extractor provided' do
      it 'does not instantiat extractor with type and args' do
        extractor = mock

        Drudgery::Extractors.expects(:instantiate).never

        job = Drudgery::Job.new
        job.extract(extractor)
      end

      it 'yields extractor if block_given' do
        extractor = mock
        extractor.expects(:col_sep).with('|')

        job = Drudgery::Job.new
        job.extract(extractor) do |ext|
          ext.col_sep '|'
        end
      end

      it 'sets extractor' do
        extractor = mock

        job = Drudgery::Job.new
        job.extract(extractor)

        job.instance_variable_get('@extractor').must_equal extractor
      end
    end
  end

  describe '#transform' do
    describe 'when transformer provided' do
      it 'sets transformer to provided transformer' do
        transformer = mock
        transformer.stubs(:register)

        job = Drudgery::Job.new
        job.transform(transformer)

        job.instance_variable_get('@transformer').must_equal transformer
      end

      it 'registers provided proc with provided transformer' do
        block = Proc.new { |data, cache| data }

        transformer = mock
        transformer.expects(:register).with(block)

        job = Drudgery::Job.new
        job.transform(transformer, &block)
      end

      it 'registers provided block with provided transformer' do
        transformer = mock
        transformer.expects(:register).with { |data, cache| data }

        job = Drudgery::Job.new
        job.transform(transformer) { |data, cache| data }
      end
    end

    describe 'when no transformer provided' do
      it 'sets transformer to default transformer' do
        transformer = mock
        transformer.stubs(:register)
        
        Drudgery::Transformer.expects(:new).returns(transformer)
        
        job = Drudgery::Job.new
        job.transform

        job.instance_variable_get('@transformer').must_equal transformer
      end

      it 'registers provided proc with default transformer' do
        block = Proc.new { |data, cache| data }

        transformer = mock
        transformer.expects(:register).with(block)
        
        Drudgery::Transformer.stubs(:new).returns(transformer)

        job = Drudgery::Job.new
        job.transform(&block)
      end

      it 'registers provided block with default transformer' do
        transformer = Drudgery::Transformer.new
        transformer.expects(:register).with { |data, cache| data }

        Drudgery::Transformer.stubs(:new).returns(transformer)

        job = Drudgery::Job.new
        job.transform { |data, cache| data }
      end
    end
  end

  describe '#load' do
    describe 'when type and args provided' do
      it 'instantiates loader with type with args' do
        Drudgery::Loaders.expects(:instantiate).with(:sqlite3, 'db.sqlite3', 'tablename')

        job = Drudgery::Job.new
        job.load(:sqlite3, 'db.sqlite3', 'tablename')
      end

      it 'yields loader if block_given' do
        loader = mock
        loader.expects(:select).with('a', 'b', 'c')

        Drudgery::Loaders.stubs(:instantiate).with(:sqlite3, 'db.sqlite3', 'tablename').returns(loader)

        job = Drudgery::Job.new
        job.load(:sqlite3, 'db.sqlite3', 'tablename') do |loader|
          loader.select('a', 'b', 'c')
        end
      end

      it 'sets loader' do
        loader = mock

        Drudgery::Loaders.expects(:instantiate).with(:sqlite3, 'db.sqlite3', 'tablename').returns(loader)

        job = Drudgery::Job.new
        job.load(:sqlite3, 'db.sqlite3', 'tablename')
        job.instance_variable_get('@loader').must_equal loader
      end
    end

    describe 'when loader provided' do
      it 'does not instantiate loader with type with args' do
        loader = mock

        Drudgery::Loaders.expects(:instantiate).never

        job = Drudgery::Job.new
        job.load(loader)
      end

      it 'yields loader if block_given' do
        loader = mock
        loader.expects(:select).with('a', 'b', 'c')

        job = Drudgery::Job.new
        job.load(loader) do |loader|
          loader.select('a', 'b', 'c')
        end
      end

      it 'sets loader' do
        loader = mock

        job = Drudgery::Job.new
        job.load(loader)
        job.instance_variable_get('@loader').must_equal loader
      end
    end
  end

  describe '#perform' do
    it 'extracts records from extractor' do
      extractor = mock
      extractor.expects(:extract).yields({ 'a' => 1 })

      loader = mock
      loader.stubs(:load)

      job = Drudgery::Job.new(:extractor => extractor, :loader => loader)

      job.perform
    end

    it 'transforms records with transformer' do
      extractor = mock
      extractor.stubs(:extract).yields({ 'a' => 1 })

      transformer = mock
      transformer.expects(:transform).with({ 'a' => 1 }).returns({ :a => 1 })

      loader = mock
      loader.stubs(:load)

      job = Drudgery::Job.new(:extractor => extractor, :transformer => transformer, :loader => loader)

      job.perform
    end

    it 'loads records with loader in batches' do
      extractor = mock
      extractor.stubs(:extract).multiple_yields([{ 'a' => 1 }], [{ 'b' => 2 }], [{ 'c' => 3 }])

      loader = mock
      loader.expects(:load).with([{ 'a' => 1 }, { 'b' => 2 }])
      loader.expects(:load).with([{ 'c' => 3 }])

      job = Drudgery::Job.new(:extractor => extractor, :loader => loader)
      job.batch_size 2

      job.perform
    end
  end
end
