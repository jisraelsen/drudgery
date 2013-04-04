Drudgery [![Build Status](https://secure.travis-ci.org/jisraelsen/drudgery.png?branch=master)](http://travis-ci.org/jisraelsen/drudgery) [![Coverage Status](https://coveralls.io/repos/jisraelsen/drudgery/badge.png?branch=master)](https://coveralls.io/r/jisraelsen/drudgery) [![Code Climate](https://codeclimate.com/badge.png)](https://codeclimate.com/github/jisraelsen/drudgery)
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

  job.transform do |data, cache|
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
  job.batch_size = 5000

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

  job.transform do |data, cache|
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

You can use your own extractors if you would like.  They need to
implement the following methods:

 * `#name` - returns extractor's name
 * `#record_count` - returns count of records in source
 * `#extract` - must yield each record and record index

```ruby
class ArrayExtractor
  attr_reader :name

  def initialize(source)
    @source = source
    @name = 'array'
  end

  def extract
    index = 0
    @source.each do |record|
      yield [record, index]
      index += 1
    end
  end

  def record_count
    @source.size
  end
end

source = []

m = Drudgery::Manager.new

m.prepare do |job|
  job.extract ArrayExtractor.new(source)
  job.load :csv, 'destination.csv'
end
```

Or, if you define your custom extractor under the Drudgery::Extractors
namespace:

```ruby
module Drudgery
  module Extractors
    class ArrayExtractor
      attr_reader :name

      def initialize(source)
        @source = source
        @name = 'array'
      end

      def extract
        index = 0
        @source.each do |record|
          yield [record, index]
          index += 1
        end
      end

      def record_count
        @source.size
      end
    end
  end
end

source = []

m = Drudgery::Manager.new

m.prepare do |job|
  job.extract :array, source
  job.load :csv, 'destination.csv'
end
```

Transformers
------------

Drudgery comes with a basic Transformer class.  It symbolizes the keys of
each record and allows you to register a processor to process data.  The
processor should implement a `#call` method and return a `Hash` or `nil`.

```ruby
custom_processor = Proc.new do |data, cache|
  data[:initials] = data[:name].split(' ').map(&:capitalize).join()
  data
end

transformer = Drudgery::Transformer.new
transformer.register(custom_processor)

transformer.transform({ :name => 'John Doe' }) # == { :name => 'John Doe', :initials => 'JD' }
```

You could also implement your own transformer if you need more custom
processing power.  If you inherit from `Drudgery::Transfomer`, you need
only implement the `#transform` method that accepts a hash argument as an
argument and returns a `Hash` or `nil`.

```ruby
class CustomTransformer < Drudgery::Transformer
  def transform(data)
    # do custom processing here
  end
end

m = Drudgery::Manager.new

m.prepare do |job|
  job.extract :csv, 'source.csv'
  job.transform CustomTransformer.new
  job.load :csv, 'destination.csv'
end
```

Loaders
-------

The following loaders are provided:

 * `:csv`
 * `:sqlite3`
 * `:active_record`
 * `:active_record_import`

You can use your own loaders if you would like.  They need to implement
the following methods:

* `#name` - returns the loader's name
* `#load` - accepts an array of records and then write them to the
  destination

```ruby
class ArrayLoader
  attr_reader :name

  def initialize(destination)
    @destination = destination
    @name = 'array'
  end

  def load(records)
    @destination.push(*records)
  end
end

destination = []

m = Drudgery::Manager.new

m.prepare do |job|
  job.extract :csv, 'source.csv'
  job.load ArrayLoader.new(destination)
end
```

Or, if you define your custom loader under the Drudgery::Loaders
namespace:

```ruby
module Drudgery
  module Loaders
    class ArrayLoader
      attr_reader :name

      def initialize(destination)
        @destination = destination
        @name = 'array'
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
  job.extract :csv, 'source.csv'
  job.load :array, destination
end
```

Event Hooks
-----------

Drudgery provides hooks so that you can listen for events and execute
your own code (e.g. logging and progress).

The following events are provided:

 * `:before_job` - Fired before the jobs starts.
 * `:after_job` - Fired after the jobs completes.
 * `:after_extract` - Fired after each record is extracted.
 * `:after_transform` - Fired after each record is transformed.
 * `:after_load` - Fired after each batch of records are loaded.

Logging
-------

Support for logging is not provided explicitly.  Here is an example
using the hooks provided:

```ruby
require 'logger'
logger = Logger.new('drudgery.log')

# before_job yields the job
Drudgery.subscribe :before_job do |job|
  logger.info "## JOB #{job.id}: #{job.name}"
end

# after_extract yields the job, record, and record index
Drudgery.subscribe :after_extract do |job, record, index|
  logger.debug "## JOB #{job.id}: Extracting Record -- Index: #{index}"
  logger.debug "## JOB #{job.id}: #{record.inspect}"
end

# after_transform yields the job, record, and record index
Drudgery.subscribe :after_transform do |job, record, index|
  logger.debug "## JOB #{job.id}: Transforming Record -- Index: #{index}"
  logger.debug "## JOB #{job.id}: #{record.inspect}"
end

# after_load yields the job and records that were loaded
Drudgery.subscribe :after_load do |job, records|
  logger.debug "## JOB #{job.id}: Loading Records -- Count: #{records.size}"
  logger.debug "## JOB #{job.id}: #{records.inspect}"
end

# after_job yields the job
Drudgery.subscribe :after_job do |job|
  logger.info "## JOB #{job.id}: Completed at #{job.completed_at}"
end
```

Progress
--------

Support for progress indication is not provided explicitly.  Here is an example
using the hooks provided:

```ruby
require 'rubygems'
require 'progressbar'

progress = {}

Drudgery.subscribe :before_job do |job|
  progress[job.id] ||= ProgressBar.new("## JOB #{job.id}", job.record_count)
end

Drudgery.subscribe :after_extract do |job, record, index|
  progress[job.id].inc
end

Drudgery.subscribe :after_job do |job|
  progress[job.id].finish
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
