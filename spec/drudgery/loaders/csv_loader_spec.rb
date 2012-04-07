require 'spec_helper'

describe Drudgery::Loaders::CSVLoader do
  describe '#initialize' do
    it 'sets filepath to provided filepath' do
      loader = Drudgery::Loaders::CSVLoader.new('file.csv')
      loader.instance_variable_get('@filepath').must_equal 'file.csv'
    end

    it 'initializes write_headers boolean' do
      loader = Drudgery::Loaders::CSVLoader.new('file.csv')
      loader.instance_variable_get('@write_headers').must_equal true
    end

    it 'sets options to provided options' do
      options = { :col_sep => '|' }

      loader = Drudgery::Loaders::CSVLoader.new('file.csv', options)
      loader.instance_variable_get('@options').must_equal({ :col_sep => '|' })
    end

    it 'sets name to csv:<file base name>' do
      loader = Drudgery::Loaders::CSVLoader.new('tmp/file.csv')
      loader.name.must_equal 'csv:file.csv'
    end
  end

  describe '#load' do
    it 'opens CSV file to append records' do
      CSV.expects(:open).with('file.csv', 'a', :col_sep => '|')

      loader = Drudgery::Loaders::CSVLoader.new('file.csv', :col_sep => '|')
      loader.load([{}])
    end

    it 'writes hash keys as header and records as rows' do
      record1 = { :a => 1, :b => 2 }
      record2 = { :a => 3, :b => 4 }
      record3 = { :a => 5, :b => 6 }

      csv = mock('csv')
      csv.expects(:<<).with([:a, :b])
      csv.expects(:<<).with([1, 2])
      csv.expects(:<<).with([3, 4])
      csv.expects(:<<).with([5, 6])

      CSV.expects(:open).with('file.csv', 'a', {}).yields(csv).times(2)

      loader = Drudgery::Loaders::CSVLoader.new('file.csv')
      loader.load([record1, record2])
      loader.load([record3])
    end
  end

  describe 'without stubs' do
    before(:each) do
      File.delete('file.csv') if File.exists?('file.csv')
    end

    after(:each) do
      File.delete('file.csv') if File.exists?('file.csv')
    end

    describe '#load' do
      it 'writes hash keys as header and records as rows' do
        record1 = { :a => 1, :b => 2 }
        record2 = { :a => 3, :b => 4 }
        record3 = { :a => 5, :b => 6 }

        loader = Drudgery::Loaders::CSVLoader.new('file.csv')
        loader.load([record1, record2])
        loader.load([record3])

        records = File.readlines('file.csv').map { |line| line.strip.split(',') }
        records.must_equal [%w[a b], %w[1 2], %w[3 4], %w[5 6]]
      end
    end
  end
end
