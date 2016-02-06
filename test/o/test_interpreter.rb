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
    @interpreter.eval('(begin (set! a 1) a)').must_equal 1
    proc { @interpreter.eval('(begin (set! a 1) b)') }.must_raise Exception
  end

  it 'should evaluate function calls' do
    @interpreter.eval('(list 1)').must_equal [1]
    @interpreter.eval('(list 2)').must_equal [2]
    @interpreter.eval('(list 2 3)').must_equal [2, 3]
    @interpreter.eval('(+ 2 3)').must_equal 5
    @interpreter.eval('(+ 2 3 10 20 100)').must_equal 135
    @interpreter.eval('(* 2 3)').must_equal 6
    @interpreter.eval('(* 2 3 1 10)').must_equal 60
    @interpreter.eval('(* 2 3 (+ 1 1))').must_equal 12
    @interpreter.eval('(* 2 3 (- 3 1))').must_equal 12
    @interpreter.eval('(/ 8 4)').must_equal 2
    @interpreter.eval('(/ 8.8 4)').must_equal 2.2
  end

  it 'should evaluate if expressions' do
    @interpreter.eval('(if #t 1 2)').must_equal 1
    @interpreter.eval('(if #f 1 2)').must_equal 2
    @interpreter.eval('(if #f 1 (if #t 2 3))').must_equal 2
    @interpreter.eval('(if #f 1 (if #f 2 3))').must_equal 3
  end

  it 'should evaluate lambda expressions' do
    @interpreter.eval('((lambda (x) x) 2)').must_equal 2
    @interpreter.eval('((lambda (y) y) 3)').must_equal 3
    @interpreter.eval('((lambda (x) (* x x)) 3)').must_equal 9
    @interpreter.eval('((lambda (y) (+ y ((lambda (x) (* x y)) 3))) 2)').must_equal 8
  end

  it 'should evaluate begin expressions' do
    @interpreter.eval('(begin (if #t 1 2) (list 1 2))').must_equal [1, 2]
    @interpreter.eval('(begin  (list 1 2) (if #t 1 2))').must_equal 1
  end

  it 'should evaluate set expressions' do
    @interpreter.eval('(begin (set! x (if #t 1 2)) x)').must_equal 1
  end

  it 'should implement comparison operations' do
    @interpreter.eval('(= 1 1)').must_equal true
    @interpreter.eval('(= 1 2)').must_equal false

    @interpreter.eval('(> 1 2)').must_equal false
    @interpreter.eval('(> 2 1)').must_equal true

    @interpreter.eval('(< 1 2)').must_equal true
    @interpreter.eval('(< 2 1)').must_equal false
    @interpreter.eval('(< 2 2)').must_equal false


    @interpreter.eval('(<= 2 2)').must_equal true
    @interpreter.eval('(<= 1 2)').must_equal true
    @interpreter.eval('(>= 2 2)').must_equal true
    @interpreter.eval('(>= 3 2)').must_equal true

    @interpreter.eval('(not #f)').must_equal true
    @interpreter.eval('(not #t)').must_equal false
  end

  it 'should implement logical operations' do
    @interpreter.eval('(or #f #f)').must_equal false
    @interpreter.eval('(or #f #t)').must_equal true
    @interpreter.eval('(or #t #f)').must_equal true

    @interpreter.eval('(and #f #f)').must_equal false
    @interpreter.eval('(and #f #t)').must_equal false
    @interpreter.eval('(and #t #f)').must_equal false
    @interpreter.eval('(and #t #t)').must_equal true
  end

  it 'should evaluate cond expressions' do
    @interpreter.eval('(cond ((= 1 1) 1) ((= 2 2) 2))').must_equal 1
    @interpreter.eval('(cond ((= 2 1) 1) ((= 2 2) 2))').must_equal 2
    @interpreter.eval('(cond ((= 2 1) 1) ((= 2 4) 2) (else 3))').must_equal 3
  end

  it 'should evaluate let expressions' do
    @interpreter.eval('(let ((x 1)) x)').must_equal 1
    @interpreter.eval('(let ((x 1) (y 2)) y)').must_equal 2
  end

  it 'should evaluate let* expressions' do
    @interpreter.eval('(let* ((x 1) (y x)) y)').must_equal 1
    @interpreter.eval('(let* ((x 1) (y (+ x 1))) y)').must_equal 2
  end
end
