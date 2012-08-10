require 'spec_helper'

module Drudgery
  describe Job do
    describe '#initialize' do
      it 'sets job id to nsec time' do
        now = Time.now
        Time.stubs(:now).returns(now)

        job = Job.new
        job.id.must_equal now.nsec
      end

      it 'sets extractor, transformer, and loader with provided arguments' do
        extractor = Extractors::CSVExtractor.new('test.csv')
        transformer = Transformer.new
        loader = Loaders::CSVLoader.new('test.csv')

        job = Job.new(
          extractor:    extractor,
          transformer:  transformer,
          loader:       loader
        )

        job.extractor.must_equal extractor
        job.transformer.must_equal transformer
        job.loader.must_equal loader
      end

      it 'sets batch_size with provided argument' do
        job = Job.new(:batch_size => 100)
        job.batch_size.must_equal 100
      end

      it 'initializes batch_size as 1000 if none provided' do
        job = Job.new
        job.batch_size.must_equal 1000
      end
    end

    describe '#name' do
      it 'returns <extractor name> => <loader name>' do
        job = Job.new(
          :extractor => Extractors::CSVExtractor.new('their-records.csv'),
          :loader => Loaders::CSVLoader.new('my-records.csv')
        )

        job.name.must_equal 'csv:their-records.csv => csv:my-records.csv'
      end
    end

    describe '#record_count' do
      describe 'when extractor exists' do
        it "returns the extractor's record_count" do
          extractor = Extractors::CSVExtractor.new('test.csv')
          extractor.stubs(:record_count).returns(1000)

          job = Job.new(extractor: extractor)
          job.record_count.must_equal 1000
        end

      end

      describe 'when extractor does not exist' do
        it 'returns nil' do
          job = Job.new
          job.record_count.must_be_nil
        end
      end
    end

    describe '#extract' do
      describe 'when type and args provided' do
        it 'instantiates extractor with type and args' do
          job = Job.new
          job.extract(:csv, 'test.csv', :col_sep => '|')

          job.extractor.name.must_equal 'csv:test.csv'
          job.extractor.col_sep.must_equal '|'
        end

        it 'yields extractor if block_given' do
          job = Job.new
          job.extract(:csv, 'test.csv') do |extractor|
            extractor.col_sep = '|'
          end

          job.extractor.name.must_equal 'csv:test.csv'
          job.extractor.col_sep.must_equal '|'
        end

        it 'sets extractor' do
          job = Job.new
          job.extract(:csv, 'test.csv', :col_sep => '|')

          job.extractor.wont_be_nil
          job.extractor.name.must_equal 'csv:test.csv'
          job.extractor.col_sep.must_equal '|'
        end
      end

      describe 'when extractor provided' do
        it 'yields extractor if block_given' do
          extractor = Extractors::CSVExtractor.new('test.csv')

          job = Job.new
          job.extract(extractor) do |ext|
            ext.col_sep = '|'
          end

          extractor.name.must_equal 'csv:test.csv'
          extractor.col_sep.must_equal '|'
        end

        it 'sets extractor' do
          extractor = Extractors::CSVExtractor.new('test.csv')

          job = Job.new
          job.extract(extractor)
          job.extractor.must_equal extractor
        end
      end
    end

    describe '#transform' do
      describe 'when transformer provided' do
        it 'registers provided proc with provided transformer' do
          block = Proc.new { |data, cache| data[:a] += 1; data }

          transformer = Transformer.new

          job = Job.new
          job.transform(transformer, &block)

          transformer.transform('a' => 1).must_equal({ :a => 2 })
        end

        it 'registers provided block with provided transformer' do
          transformer = Transformer.new

          job = Job.new
          job.transform(transformer) { |data, cache| data[:a] += 2; data }

          transformer.transform('a' => 1).must_equal({ :a => 3 })
        end

        it 'sets transformer' do
          transformer = Transformer.new

          job = Job.new
          job.transform(transformer)

          transformer.must_equal transformer
        end
      end

      describe 'when no transformer provided' do
        it 'registers provided proc with default transformer' do
          block = Proc.new { |data, cache| data[:a] += 1; data }

          job = Job.new
          job.transform(&block)
          job.transformer.transform('a' => 1).must_equal({ :a => 2 })
        end

        it 'registers provided block with default transformer' do
          job = Job.new
          job.transform { |data, cache| data[:a] += 2; data }
          job.transformer.transform('a' => 1).must_equal({ :a => 3 })
        end


        it 'sets transformer to default transformer' do
          job = Job.new
          job.transform
          job.transformer.must_be_instance_of Transformer
        end
      end
    end

    describe '#load' do
      describe 'when type and args provided' do
        it 'instantiates loader with type with args' do
          job = Job.new
          job.load(:csv, 'test.csv', :col_sep => '|')

          job.loader.name.must_equal 'csv:test.csv'
          job.loader.col_sep.must_equal '|'
        end

        it 'yields loader if block_given' do
          job = Job.new
          job.load(:csv, 'test.csv') do |loader|
            loader.col_sep = '|'
          end

          job.loader.name.must_equal 'csv:test.csv'
          job.loader.col_sep.must_equal '|'
        end

        it 'sets loader' do
          job = Job.new
          job.load(:csv, 'test.csv', :col_sep => '|')

          job.loader.wont_be_nil
          job.loader.name.must_equal 'csv:test.csv'
          job.loader.col_sep.must_equal '|'
        end
      end

      describe 'when loader provided' do
        it 'yields loader if block_given' do
          loader = Loaders::CSVLoader.new('test.csv')

          job = Job.new
          job.load(loader) do |loader|
            loader.col_sep = '|'
          end

          loader.name.must_equal 'csv:test.csv'
          loader.col_sep.must_equal '|'
        end

        it 'sets loader' do
          loader = Loaders::CSVLoader.new('test.csv')

          job = Job.new
          job.load(loader)
          job.loader.must_equal loader
        end
      end
    end

    describe '#perform' do
      before do
        @source = 'tmp/source.csv'
        @destination = 'tmp/destination.csv'
        File.delete(@source) if File.exists?(@source)
        File.delete(@destination) if File.exists?(@destination)

        File.open(@source, 'w') do |f|
          f.puts 'a,b'
          f.puts '1,2'
          f.puts '3,4'
          f.puts '5,6'
        end

        @extractor = Extractors::CSVExtractor.new(@source)
        @loader = Loaders::CSVLoader.new(@destination)

        @job = Job.new(:extractor => @extractor, :loader => @loader, :transformer => @transformer)
      end

      after do
        File.delete(@source) if File.exists?(@source)
        File.delete(@destination) if File.exists?(@destination)
      end

      it 'sets started_at and completed_at' do
        @job.perform

        @job.started_at.must_be_instance_of Time
        @job.completed_at.must_be_instance_of Time
        @job.completed_at.must_be :>, @job.started_at
      end

      it 'extracts records from extractor and loads records with loader' do
        @job.perform

        records = File.readlines(@destination).map { |line| line.strip.split(',') }
        records.must_equal [%w[a b], %w[1 2], %w[3 4], %w[5 6]]
      end

      it 'transforms records with transformer' do
        transformer = Transformer.new
        transformer.register Proc.new { |data, cache| data[:c] = 99; data }

        @job.transformer = transformer
        @job.perform

        records = File.readlines(@destination).map { |line| line.strip.split(',') }
        records.must_equal [%w[a b c], %w[1 2 99], %w[3 4 99], %w[5 6 99]]
      end

      it 'skips nil records' do
        transformer = Transformer.new
        transformer.register Proc.new { |data, cache| data[:a] == '1' ? nil : data }

        @job.transformer = transformer
        @job.perform

        records = File.readlines(@destination).map { |line| line.strip.split(',') }
        records.must_equal [%w[a b], %w[3 4], %w[5 6]]
      end

      it 'does not load empty records' do
        transformer = Transformer.new
        transformer.register Proc.new { |data, cache| nil}

        @loader.expects(:load).never

        @job.transformer = transformer
        @job.perform
      end

      it 'loads records with loader in batches' do
        @job.batch_size = 2

        @loader.expects(:load).with([{ 'a' => '1', 'b' => '2' }, { 'a' => '3', 'b' => '4' }])
        @loader.expects(:load).with([{ 'a' => '5', 'b' => '6' }])

        @job.perform
      end
    end
  end
end
