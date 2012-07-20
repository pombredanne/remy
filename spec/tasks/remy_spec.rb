require 'spec_helper'
require 'rake'

describe 'background.rake' do
  before do
    Rake.application.rake_require "tasks/remy"
    Rake::Task.define_task(:environment)
  end

  it 'should run task foo' do
    Remy::Config::Chef.should_receive(:save_node_json).with('my/path/to/node.json')
    Rake.application['remy:save_node_json'].invoke('my/path/to/node.json')
  end
end