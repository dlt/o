require 'test_helper'

describe O::Parser do
  before do
    @parser = O::Parser.new
  end

  it 'should parse an int' do
    @parser.parse("1").must_equal  integer: 1
    @parser.parse("-1").must_equal  integer: -1
  end

  it 'should parse a string' do
    @parser.parse('"a string"').must_equal  string: 'a string'
  end

  it 'should parse a boolean' do
    @parser.parse('#f').must_equal  boolean: false
    @parser.parse('#t').must_equal  boolean: true
  end

  it 'should parse floats' do
    @parser.parse('1.0').must_equal  float: 1.0
    @parser.parse('0.0001').must_equal  float: 0.0001
  end

  it 'should parse identifiers' do
    @parser.parse('lambda').must_equal  symbol: :lambda
    @parser.parse('-def').must_equal  symbol: :"-def"
    @parser.parse('another-symbol').must_equal  symbol: :"another-symbol"
  end

  it 'should parse funcalls' do
    @parser.parse('(list   1   )').must_equal  funcall: { funcname: {symbol: :list}, args: [{ integer: 1}] }
    @parser.parse('(list  "string")').must_equal  funcall: { funcname: {symbol: :list}, args: [{ string: "string" }] }
    @parser.parse('(list 1 2 3)').must_equal  funcall: { funcname: {symbol: :list}, args: [{ integer: 1}, {integer: 2}, {integer: 3}] }
    @parser.parse('(list  (list 1))').must_equal  funcall: { funcname: {symbol: :list}, args: [{funcall: { funcname: {symbol: :list}, args: [{ integer: 1}] } }] }
    @parser.parse('(list  (list "string"))').must_equal  funcall: { funcname: {symbol: :list}, args: [{funcall: { funcname: {symbol: :list}, args: [{ string: "string" }] } }] }
  end

  it 'should parse if expressions' do
    @parser.parse('(if #t 1 2)').must_equal if: { test: { boolean: true }, conseq: { integer: 1 }, alt: { integer: 2 } }
  end

  it 'should parse lambda expressions' do
    @parser.parse('(lambda (x) (1))').must_equal lambda: { formal_params: [{ symbol: :x }], lambda_body: [{integer: 1}]  }
  end
end
