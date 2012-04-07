require 'spec_helper'

describe ProgressBar do
  describe '#title_width=' do
    it 'sets title_width' do
      out = StringIO.new

      progressbar = ProgressBar.new('test', 1, out)
      progressbar.title_width = 10
      progressbar.instance_variable_get('@title_width').must_equal 10
    end
  end
end
