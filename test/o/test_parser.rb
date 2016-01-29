require 'test_helper'

describe O::Parser do
  before do
    @parser = O::Parser.new
  end

  it 'should parse a int' do
    @parser.parse("1").should == { number: 1 }
  end

end
