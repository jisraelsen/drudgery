Drudgery [![Build Status](https://secure.travis-ci.org/jisraelsen/drudgery.png?branch=master)](http://travis-ci.org/jisraelsen/drudgery)
========

A simple ETL library that supports the following sources/destinations:

 * CSV and other delimited file formats (e.g. pipe, tab, etc)
 * SQLite3
 * ActiveRecord (bulk insert support using activerecord-import)

Supported Rubies:

 * Ruby 1.9.2, 1.9.3

Install
-------

Install the gem directly:

```bash
gem install drudgery
```

Or, add it to your Gemfile:

```ruby
gem 'drudgery'
```

And, if using the `:sqlite3` extractor or loader:

```ruby
gem 'sqlite3', '~> 1.3'
```

And, if using the `:active_record` extractor or loader:

```ruby
gem 'activerecord', '~> 3.0'
```

And, if using the `:active_record_import` loader:

```ruby
gem 'activerecord-import', '>= 0.2.9'
```

Usage
-----

Extracting from CSV and loading into ActiveRecord:

```ruby
m = Drudgery::Manager.new

m.prepare do |job|
  job.extract :csv, 'src/addresses.csv'

  job.transform do |data|
    first_name, last_name = data.delete(:name).split(' ')

    data[:first_name] = first_name
    data[:last_name]  = last_name
    data[:state]      = data.delete(:state_abbr)

    data
  end

  job.load :active_record, Address
end

m.run
```

Extracting from SQLite3 and bulk loading into ActiveRecord:

```ruby
db = SQLite3::Database.new('db.sqlite3')

m = Drudgery::Manager.new

m.prepare do |job|
  job.batch_size 5000

  job.extract :sqlite3, db, 'addresses' do |extractor|
    extractor.select(
      'name',
      'street_address',
      'city',
      'state_abbr AS state',
      'zip'
    )
    extractor.where("state LIKE 'A%'")
    extractor.order('name')
  end

  job.transform do |data|
    first_name, last_name = data.delete(:name).split(' ')

    data[:first_name] = first_name
    data[:last_name]  = last_name

    data
  end

  job.load :active_record_import, Address
end

m.run
```

Extractors
----------

The following extractors are provided: `:csv`, `:sqlite3`, `:active_record`

You can use your own extractors if you would like.  They need only
implement an `#extract` method that yields each record:

```ruby
class ArrayExtractor
  def initialize(source)
    @source = source
  end

  def extract
    @source.each do |record|
      yield record
    end    
  end
end

source = []

m = Drudgery::Manager.new
job = Drudgery::Job.new(:extractor => ArrayExtractor.new(source))

m.prepare(job) do |job|
  m.load :csv, 'destination.csv'
end
```

Or, if you define your custom extractor under the Drudgery::Extractors
namespace:

```ruby
module Drudgery
  module Extractors
    class ArrayExtractor
      def initialize(source)
        @source = source
      end

      def extract
        @source.each do |record|
          yield record
        end
      end
    end
  end
end

source = []

m = Drudgery::Manager.new

m.prepare do |job|
  m.extract :array, source
  m.load :csv, 'destination.csv'
end
```

Transformers
------------

Drudgery comes with a basic Transformer class.  It symbolizes the keys of
each record and allows you to register processors to process data.  Registered
processors should implement a `#call` method and return a `Hash` or `nil`.

```ruby
custom_processor = Proc.new do |data, cache|
  data[:initials] = data[:name].split(' ').map(&:capitalize)
  data
end

transformer = Drudgery::Transformer.new
transformer.register(custom_processor)

transformer.transform({ :name => 'John Doe' }) # == { :name => 'John Doe', :initials => 'JD' }
```

You could also implement your own transformer if you need more custom
processing power.  If you inherit from `Drudgery::Transfomer`, you need
only implement the `#transform` method that accepts a hash as an
argument and returns a `Hash` or `nil`.

```ruby
class CustomTransformer < Drudgery::Transformer
  def transform(data)
    # do custom processing here
  end
end

m = Drudgery::Manager.new
job = Drudgery::Job.new(:transformer => CustomTransformer.new)

m.prepare(job) do |job|
  m.extract :csv, 'source.csv'
  m.load :csv, 'destination.csv'
end
```

Loaders
-------

The following loaders are provided:

 * `:csv`
 * `:sqlite3`
 * `:active_record`
 * `:active_record_import`

You can use your own loaders if you would like.  They need only
implement a `#load` method that accepts an array of records as an
argument and then writes/inserts them to the destination.

```ruby
class ArrayLoader
  def initialize(destination)
    @destination = destination
  end

  def load(records)
    @destination.push(*records)
  end
end

destination = []

m = Drudgery::Manager.new
job = Drudgery::Job.new(:loader => ArrayLoader.new(destination))

m.prepare(job) do |job|
  m.extract :csv, 'source.csv'
end
```

Or, if you define your custom loader under the Drudgery::Loaders
namespace:

```ruby
module Drudgery
  module Loaders
    class ArrayLoader
      def initialize(destination)
        @destination = destination
      end

      def load(records)
        @destination.push(*records)
      end
    end
  end
end

destination = []

m = Drudgery::Manager.new

m.prepare do |job|
  m.extract :csv, 'source.csv'
  m.load :array, destination
end
```

Contributing
------------

Pull requests are welcome.  Just make sure to include tests!

To run tests, install some dependencies:

```bash
bundle install
```

Then, run tests with:

```bash
rake test
```

Or, If you want to check coverage:

```bash
COVERAGE=true rake test
```

Issues
------

Please use GitHub's [issue tracker](http://github.com/jisraelsen/drudgery/issues).

Author
------

[Jeremy Israelsen](http://github.com/jisraelsen)
