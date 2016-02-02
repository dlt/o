require 'test_helper'

describe O::Parser do
  before do
    @parser = O::Parser.new
  end

  it 'should parse a int' do
    @parser.parse("1").must_equal  integer: 1
    @parser.parse("-1").must_equal  integer: -1
  end

  it 'should parse a string' do
    @parser.parse('"a string"').must_equal  string: 'a string'
  end
end
