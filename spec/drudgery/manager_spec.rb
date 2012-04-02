require 'spec_helper'

describe Drudgery::Manager do
  before(:each) do
    @manager = Drudgery::Manager.new
  end

  describe '#initialize' do
    it 'initializes jobs array' do
      @manager.instance_variable_get('@jobs').must_equal []
    end
  end

  describe '#prepare' do
    it 'adds obj to jobs array' do
      job = mock

      @manager.prepare(job)
      @manager.instance_variable_get('@jobs').must_include job
    end
  end

  describe '#run' do
    it 'performs each job' do
      job1 = mock
      job1.expects(:perform)

      job2 = mock
      job2.expects(:perform)

      job3 = mock
      job3.expects(:perform).never

      @manager.prepare(job1)
      @manager.prepare(job2)
      @manager.run
    end
  end
end
