require 'spec_helper'

describe Drudgery::JobProgress do
  describe '#initialize' do
    before(:each) do
      STDERR.stubs(:print)
    end

    it 'sets title to ## JOB <id>' do
      progress = Drudgery::JobProgress.new(123, 1)
      progress.instance_variable_get('@title').must_equal '## JOB 123'
    end

    it 'sets title_with to title.length + 1' do
      progress = Drudgery::JobProgress.new(123, 1)
      progress.instance_variable_get('@title_width').must_equal '## JOB 123'.length + 1
    end
  end
end
