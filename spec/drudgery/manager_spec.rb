require 'spec_helper'

module Drudgery
  describe Manager do
    let(:manager) { Manager.new }

    describe '#prepare' do
      it 'accepts job as an argument' do
        job = Job.new

        manager.prepare(job)
      end

      it 'allows configuration of job via block' do
        manager.prepare do |job|
          job.extract :csv, 'records.csv'
        end
      end
    end

    describe '#run' do
      it 'performs each prepared job' do
        job1 = Job.new
        job2 = Job.new
        job3 = Job.new

        job1.expects(:perform)
        job2.expects(:perform)
        job3.expects(:perform).never

        manager.prepare(job1)
        manager.prepare(job2)
        manager.run
      end
    end
  end
end
