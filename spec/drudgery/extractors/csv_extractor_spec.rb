require 'spec_helper'

describe Drudgery::Extractors::CSVExtractor do
  describe '#initialize' do
    it 'sets filepath to provided filepath' do
      extractor = Drudgery::Extractors::CSVExtractor.new('file.csv')
      extractor.instance_variable_get('@filepath').must_equal 'file.csv'
    end

    it 'initializes options hash' do
      extractor = Drudgery::Extractors::CSVExtractor.new('file.csv')
      extractor.instance_variable_get('@options').must_equal({ :headers => true })
    end

    it 'merges provided options with default options' do
      options = { :col_sep => '|', :headers => %w[id name email] }

      extractor = Drudgery::Extractors::CSVExtractor.new('file.csv', options)
      extractor.instance_variable_get('@options').must_equal({ :col_sep => '|', :headers => %w[id name email] })
    end
  end

  describe '#extract' do
    it 'parses records from file' do
      CSV.expects(:foreach).with('file.csv', :headers => true)

      extractor = Drudgery::Extractors::CSVExtractor.new('file.csv')
      extractor.extract
    end

    it 'yields each record as a hash' do
      record1 = mock
      record1.expects(:to_hash).returns({ :a => 1 })

      record2 = mock
      record2.expects(:to_hash).returns({ :b => 2 })

      CSV.stubs(:foreach).multiple_yields([record1], [record2])

      extractor = Drudgery::Extractors::CSVExtractor.new('file.csv')

      records = []
      extractor.extract do |record|
        records << record
      end

      records[0].must_equal({ :a => 1 })
      records[1].must_equal({ :b => 2 })
    end

    describe 'without stubs' do
      before(:each) do
        File.delete('file.csv') if File.exists?('file.csv')
      end

      after(:each) do
        File.delete('file.csv') if File.exists?('file.csv')
      end

      it 'writes hash keys as header and records as rows' do
        File.open('file.csv', 'w') do |f|
          f.puts 'a,b'
          f.puts '1,2'
          f.puts '3,4'
          f.puts '5,6'
        end

        extractor = Drudgery::Extractors::CSVExtractor.new('file.csv')

        records = []
        extractor.extract do |record|
          records << record
        end

        records.must_equal([
          { 'a' => '1', 'b' => '2' },
          { 'a' => '3', 'b' => '4' },
          { 'a' => '5', 'b' => '6' }
        ])
      end
    end
  end
end
