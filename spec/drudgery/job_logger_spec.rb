require 'spec_helper'

describe Drudgery::JobLogger do
  describe '#initialize' do
    it 'sets prefix to ## JOB <id>' do
      logger = Drudgery::JobLogger.new(345)
      logger.instance_variable_get('@prefix').must_equal '## JOB 345'
    end
  end

  describe '#log_with_progress' do
    before(:each) do
      @logger = Drudgery::JobLogger.new(123)
      STDERR.stubs(:puts)
      Drudgery.stubs(:log)
    end

    describe 'when progress on' do
      before(:each) do
        Drudgery.show_progress = true
      end

      it 'puts formatted message to STDERR' do
        STDERR.expects(:puts).with('## JOB 123: Some message')
        @logger.log_with_progress :info, 'Some message'
      end

      it 'passes mode and formatted message to Drudgery logger' do
        Drudgery.expects(:log).with(:info, '## JOB 123: Some message')
        @logger.log_with_progress :info, 'Some message'
      end
    end

    describe 'when progress off' do
      before(:each) do
        Drudgery.show_progress = false
      end

      it 'does not put formatted message to STDERR' do
        STDERR.expects(:puts).never
        @logger.log_with_progress :info, 'Some message'
      end

      it 'passes mode and formatted message to Drudgery logger' do
        Drudgery.expects(:log).with(:info, '## JOB 123: Some message')
        @logger.log_with_progress :info, 'Some message'
      end
    end
  end

  describe '#log' do
    it 'passes mode and formatted message to Drudgery logger' do
      Drudgery.expects(:log).with(:debug, '## JOB 234: Another message')

      logger = Drudgery::JobLogger.new(234)
      logger.log :debug, 'Another message'
    end
  end
end
