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

    it 'initializes extractor, transformer, and loader if none provided' do
      job = Drudgery::Job.new
      job.instance_variable_get('@extractor').must_be_nil
      job.instance_variable_get('@transformer').must_be_instance_of(Drudgery::Transformer)
      job.instance_variable_get('@loader').must_be_nil
    end

    it 'initializes records as array' do
      @job.instance_variable_get('@records').must_equal []
    end

    it 'initializes batch_size as 1000' do
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
    it 'instantiates extractor with type and args' do
      Drudgery::Extractors.expects(:instantiate).with(:csv, 'filename.csv', :col_sep => '|')

      job = Drudgery::Job.new
      job.extract(:csv, 'filename.csv', :col_sep => '|')
    end

    it 'sets extractor' do
      extractor = mock

      Drudgery::Extractors.stubs(:instantiate).returns(extractor)

      job = Drudgery::Job.new
      job.extract(:csv, 'filename.csv', :col_sep => '|')

      job.instance_variable_get('@extractor').must_equal extractor
    end
  end

  describe '#transform' do
    it 'registers provided proc with transformer' do
      block = Proc.new { |data, cache| data }

      transformer = mock
      transformer.expects(:register).with(block)

      job = Drudgery::Job.new(:transformer => transformer)
      job.transform(&block)
    end

    it 'registers provided block with transformer' do
      transformer = mock
      transformer.expects(:register).with { |data, cache| data }

      job = Drudgery::Job.new(:transformer => transformer)
      job.transform { |data, cache| data }
    end
  end

  describe '#load' do
    it 'instantiates loader with type with args' do
      Drudgery::Loaders.expects(:instantiate).with(:sqlite3, 'db.sqlite3', 'tablename')

      job = Drudgery::Job.new
      job.load(:sqlite3, 'db.sqlite3', 'tablename')
    end

    it 'sets extractor' do
      loader = mock

      Drudgery::Loaders.expects(:instantiate).with(:sqlite3, 'db.sqlite3', 'tablename').returns(loader)

      job = Drudgery::Job.new
      job.load(:sqlite3, 'db.sqlite3', 'tablename')
      job.instance_variable_get('@loader').must_equal loader
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
      loader.expects(:load).with([{ :a => 1 }, { :b => 2 }])
      loader.expects(:load).with([{ :c => 3 }])

      job = Drudgery::Job.new(:extractor => extractor, :loader => loader)
      job.batch_size 2

      job.perform
    end
  end
end
