require 'test_helper'

describe O::Environment do
  before do
    @environment = O::Interpreter.new.top_level_environment
  end

  it 'should implement builtin functions' do
    @environment.keys.sort.must_equal %i(list * + - /).sort
  end

end
