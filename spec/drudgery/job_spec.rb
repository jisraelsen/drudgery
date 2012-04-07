require 'spec_helper'

describe Drudgery::Job do
  describe '#initialize' do
    before(:each) do
      @extractor = stub('extractor')
      @transformer = stub('transformer')
      @loader = stub('loader')

      @now = Time.now
      Time.stubs(:now).returns(@now)

      @job = Drudgery::Job.new(:extractor => @extractor, :transformer => @transformer, :loader => @loader)
    end

    it 'sets job id to nsec time' do
      @job.id.must_equal @now.nsec
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

  describe '#name' do
    it 'returns <extractor name> => <loader name>' do
      extractor = stub('extractor', :name => 'csv:file.csv')
      loader = stub('loader', :name => 'sqlite3:memory.tablename')

      job = Drudgery::Job.new(:extractor => extractor, :loader => loader)
      job.name.must_equal 'csv:file.csv => sqlite3:memory.tablename'
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
        extractor = mock('extractor')
        extractor.expects(:col_sep).with('|')

        Drudgery::Extractors.stubs(:instantiate).returns(extractor)

        job = Drudgery::Job.new
        job.extract(:csv, 'filename.csv') do |extractor|
          extractor.col_sep '|'
        end
      end

      it 'sets extractor' do
        extractor = stub('extractor')

        Drudgery::Extractors.stubs(:instantiate).returns(extractor)

        job = Drudgery::Job.new
        job.extract(:csv, 'filename.csv', :col_sep => '|')

        job.instance_variable_get('@extractor').must_equal extractor
      end
    end

    describe 'when extractor provided' do
      it 'does not instantiat extractor with type and args' do
        extractor = stub('extractor')

        Drudgery::Extractors.expects(:instantiate).never

        job = Drudgery::Job.new
        job.extract(extractor)
      end

      it 'yields extractor if block_given' do
        extractor = mock('extractor')
        extractor.expects(:col_sep).with('|')

        job = Drudgery::Job.new
        job.extract(extractor) do |ext|
          ext.col_sep '|'
        end
      end

      it 'sets extractor' do
        extractor = stub('extractor')

        job = Drudgery::Job.new
        job.extract(extractor)

        job.instance_variable_get('@extractor').must_equal extractor
      end
    end
  end

  describe '#transform' do
    describe 'when transformer provided' do
      it 'sets transformer to provided transformer' do
        transformer = stub('transformer', :register => nil)

        job = Drudgery::Job.new
        job.transform(transformer)

        job.instance_variable_get('@transformer').must_equal transformer
      end

      it 'registers provided proc with provided transformer' do
        block = Proc.new { |data, cache| data }

        transformer = mock('transformer')
        transformer.expects(:register).with(block)

        job = Drudgery::Job.new
        job.transform(transformer, &block)
      end

      it 'registers provided block with provided transformer' do
        transformer = mock('transformer')
        transformer.expects(:register).with { |data, cache| data }

        job = Drudgery::Job.new
        job.transform(transformer) { |data, cache| data }
      end
    end

    describe 'when no transformer provided' do
      it 'sets transformer to default transformer' do
        transformer = stub('transformer', :register => nil)

        Drudgery::Transformer.expects(:new).returns(transformer)

        job = Drudgery::Job.new
        job.transform

        job.instance_variable_get('@transformer').must_equal transformer
      end

      it 'registers provided proc with default transformer' do
        block = Proc.new { |data, cache| data }

        transformer = mock('transformer')
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
        loader = mock('loader')
        loader.expects(:select).with('a', 'b', 'c')

        Drudgery::Loaders.stubs(:instantiate).with(:sqlite3, 'db.sqlite3', 'tablename').returns(loader)

        job = Drudgery::Job.new
        job.load(:sqlite3, 'db.sqlite3', 'tablename') do |loader|
          loader.select('a', 'b', 'c')
        end
      end

      it 'sets loader' do
        loader = stub('loader')

        Drudgery::Loaders.expects(:instantiate).with(:sqlite3, 'db.sqlite3', 'tablename').returns(loader)

        job = Drudgery::Job.new
        job.load(:sqlite3, 'db.sqlite3', 'tablename')
        job.instance_variable_get('@loader').must_equal loader
      end
    end

    describe 'when loader provided' do
      it 'does not instantiate loader with type with args' do
        loader = stub('loader')

        Drudgery::Loaders.expects(:instantiate).never

        job = Drudgery::Job.new
        job.load(loader)
      end

      it 'yields loader if block_given' do
        loader = mock('loader')
        loader.expects(:select).with('a', 'b', 'c')

        job = Drudgery::Job.new
        job.load(loader) do |loader|
          loader.select('a', 'b', 'c')
        end
      end

      it 'sets loader' do
        loader = stub('loader')

        job = Drudgery::Job.new
        job.load(loader)
        job.instance_variable_get('@loader').must_equal loader
      end
    end
  end

  def stub_logging
    Drudgery.stubs(:log)
  end

  describe '#perform' do
    it 'extracts records from extractor' do
      Drudgery.show_progress = false
      stub_logging

      extractor = stub('extractor', :record_count => 1, :name => 'extractor')
      extractor.expects(:extract).yields([{ 'a' => 1 }, 0])

      loader = stub('loader', :name => 'loader', :load => nil)

      job = Drudgery::Job.new(:extractor => extractor, :loader => loader)

      job.perform
    end

    it 'transforms records with transformer' do
      Drudgery.show_progress = false
      stub_logging

      extractor = stub('extractor', :record_count => 1, :name => 'extractor')
      extractor.stubs(:extract).yields([{ 'a' => 1 }, 0])

      transformer = mock('transformer')
      transformer.expects(:transform).with({ 'a' => 1 }).returns({ :a => 1 })

      loader = stub('loader', :name => 'loader', :load => nil)

      job = Drudgery::Job.new(:extractor => extractor, :transformer => transformer, :loader => loader)

      job.perform
    end

    it 'skips nil records' do
      Drudgery.show_progress = false
      stub_logging

      extractor = stub('extractor', :record_count => 1, :name => 'extractor')
      extractor.stubs(:extract).yields([{ 'a' => 1 }, 0])

      transformer = mock('transformer')
      transformer.expects(:transform).with({ 'a' => 1 }).returns(nil)

      loader = stub('loader', :name => 'loader')
      loader.expects(:load).with([{ '1' => 1 }]).never

      job = Drudgery::Job.new(:extractor => extractor, :transformer => transformer, :loader => loader)

      job.perform
    end

    it 'does not load empty records' do
      Drudgery.show_progress = false
      stub_logging

      extractor = stub('extractor', :record_count => 1, :name => 'extractor')
      extractor.stubs(:extract)

      loader = stub('loader', :name => 'loader')
      loader.expects(:load).with([]).never

      job = Drudgery::Job.new(:extractor => extractor, :loader => loader)

      job.perform
    end

    it 'loads records with loader in batches' do
      Drudgery.show_progress = false
      stub_logging

      extractor = stub('extractor', :record_count => 3, :name => 'extractor')
      extractor.stubs(:extract).multiple_yields([{ 'a' => 1 }, 0], [{ 'b' => 2 }, 1], [{ 'c' => 3 }, 2])

      loader = stub('loader', :name => 'loader')
      loader.expects(:load).with([{ 'a' => 1 }, { 'b' => 2 }])
      loader.expects(:load).with([{ 'c' => 3 }])

      job = Drudgery::Job.new(:extractor => extractor, :loader => loader)
      job.batch_size 2

      job.perform
    end

    describe 'with progress on' do
      it 'tracks progress information' do
        Drudgery.show_progress = true
        stub_logging

        extractor = stub('extractor', :record_count => 3, :name => 'extractor')
        extractor.stubs(:extract).multiple_yields([{ 'a' => 1 }, 0], [{ 'b' => 2 }, 1], [{ 'c' => 3 }, 2])

        loader = stub('loader', :name => 'loader', :load => nil)

        job = Drudgery::Job.new(:extractor => extractor, :loader => loader)

        job_prefix = "## JOB #{job.id}"

        progressbar = mock('progressbar') do
          expects(:title_width=).with(job_prefix.length + 1)
          expects(:inc).times(3)
          expects(:finish)
        end
        ProgressBar.stubs(:new).with(job_prefix, 3).returns(progressbar)

        Benchmark.stubs(:realtime).returns(5.212121).yields
        STDERR.expects(:puts).with("#{job_prefix}: extractor => loader")
        STDERR.expects(:puts).with("#{job_prefix}: Completed in 5.21s\n\n")

        job.perform
      end
    end

    describe 'with progress off' do
      it 'tracks progress information' do
        Drudgery.show_progress = false
        stub_logging

        extractor = stub('extractor', :record_count => 3, :name => 'extractor')
        extractor.stubs(:extract).multiple_yields([{ 'a' => 1 }, 0], [{ 'b' => 2 }, 1], [{ 'c' => 3 }, 2])

        loader = stub('loader', :name => 'loader', :load => nil)

        job = Drudgery::Job.new(:extractor => extractor, :loader => loader)

        STDERR.expects(:puts).never
        ProgressBar.expects(:new).never

        job.perform
      end
    end

    it 'logs job details' do
      Drudgery.show_progress = false

      extractor = stub('extractor', :record_count => 3, :name => 'extractor')
      extractor.stubs(:extract).multiple_yields([{ 'a' => 1 }, 0], [{ 'b' => 2 }, 1], [{ 'c' => 3 }, 2])

      loader = stub('loader', :name => 'loader', :load => nil)

      job = Drudgery::Job.new(:extractor => extractor, :loader => loader)
      job.batch_size 2

      job_prefix = "## JOB #{job.id}"

      Benchmark.stubs(:realtime).returns(1.25333).yields
      Drudgery.expects(:log).with(:info,  "#{job_prefix}: extractor => loader")

      Drudgery.expects(:log).with(:debug, "#{job_prefix}: Extracting Record -- Index: 0")
      Drudgery.expects(:log).with(:debug, "#{job_prefix}: #{{ 'a' => 1 }.inspect}")
      Drudgery.expects(:log).with(:debug, "#{job_prefix}: Transforming Record -- Index: 0")
      Drudgery.expects(:log).with(:debug, "#{job_prefix}: #{{ 'a' => 1 }.inspect}")
      Drudgery.expects(:log).with(:debug, "#{job_prefix}: Extracting Record -- Index: 1")
      Drudgery.expects(:log).with(:debug, "#{job_prefix}: #{{ 'b' => 2 }.inspect}")
      Drudgery.expects(:log).with(:debug, "#{job_prefix}: Transforming Record -- Index: 1")
      Drudgery.expects(:log).with(:debug, "#{job_prefix}: #{{ 'b' => 2 }.inspect}")
      Drudgery.expects(:log).with(:debug, "#{job_prefix}: Loading Records -- Count: 2")
      Drudgery.expects(:log).with(:debug, "#{job_prefix}: #{[{ 'a' => 1 }, { 'b' => 2 }].inspect}")

      Drudgery.expects(:log).with(:debug, "#{job_prefix}: Extracting Record -- Index: 2")
      Drudgery.expects(:log).with(:debug, "#{job_prefix}: #{{ 'c' => 3 }.inspect}")
      Drudgery.expects(:log).with(:debug, "#{job_prefix}: Transforming Record -- Index: 2")
      Drudgery.expects(:log).with(:debug, "#{job_prefix}: #{{ 'c' => 3 }.inspect}")
      Drudgery.expects(:log).with(:debug, "#{job_prefix}: Loading Records -- Count: 1")
      Drudgery.expects(:log).with(:debug, "#{job_prefix}: #{[{ 'c' => 3 }].inspect}")

      Drudgery.expects(:log).with(:info,  "#{job_prefix}: Completed in 1.25s\n\n")

      job.perform
    end
  end
end
