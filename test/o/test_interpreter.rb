require 'test_helper'

describe O::Interpreter do
  before do
    @interpreter = O::Interpreter.new
  end


  it 'should evaluate an int' do
    @interpreter.eval("1").must_equal 1
  end

  it 'should evaluate a float' do
    @interpreter.eval("1.503").must_equal 1.503
  end

  it 'should evaluate a string' do
    @interpreter.eval('"a string"').must_equal "a string"
  end

  it 'should evaluate a symbol' do
    @interpreter.eval('a-symbol').must_equal :"a-symbol"
  end

  it 'should evaluate function calls' do
    @interpreter.eval('(list 1)').must_equal [1]
    @interpreter.eval('(list 2)').must_equal [2]
    @interpreter.eval('(list 2 3)').must_equal [2, 3]
    @interpreter.eval('(+ 2 3)').must_equal 5
    @interpreter.eval('(+ 2 3 10 20 100)').must_equal 135
    @interpreter.eval('(* 2 3)').must_equal 6
    @interpreter.eval('(* 2 3 1 10)').must_equal 60
  end

  it 'should evaluate if expressions' do
    @interpreter.eval('(if #t 1 2)').must_equal 1
    @interpreter.eval('(if #f 1 2)').must_equal 2
    @interpreter.eval('(if #f 1 (if #t 2 3))').must_equal 2
    @interpreter.eval('(if #f 1 (if #f 2 3))').must_equal 3
  end
end
