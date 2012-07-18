require 'spec_helper'

describe Remy::Utility do
  describe 'instance methods' do
    subject do
      Class.new do
        include Remy::Utility
      end.new
    end
    describe '#flatten_paths' do
      let(:base_path) {  }
      let(:expected_paths) { [File.expand_path('a'), File.expand_path('b')] }
      it 'should return a map of paths for arrays' do
        subject.flatten_paths(['a'], ['b']).should == expected_paths
      end

      it 'should return a map of paths for strings (regression for 1.9.2)' do
        subject.flatten_paths('a', 'b').should == expected_paths
      end
    end
  end
end