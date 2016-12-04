require 'test_helper'

describe O::VM do
  before do
    @vm = O::VM::Machine::create([:regname1, :regname2], {}, [])
  end

  it 'should parse an int' do
    @vm.set_register_contents(:regname1, 1).must_equal true
    @vm.get_register_contents(:regname1).must_equal 1

    @vm.set_register_contents(:regname2, 2).must_equal true
    @vm.get_register_contents(:regname2).must_equal 2
  end

  it 'should sucessfully execute an assign expression' do
    controller = [[:assign, :t, [:const, 1]]]
    @vm = O::VM::Machine.create(%i(a b t), {}, controller)
    @vm.start
    @vm.get_register_contents(:t).must_equal 1
  end

  it 'should sucessfully execute bytecode for gcd operation' do
    equals = ->(a, b) { a == b }
    remainder = -> (a, b) { a % b }
    controller = [
      :test_b,
        [:test, [:op, :'='], [:reg, :b], [:const, 0]],
        [:branch, [:label, :gcd_done]],
        [:assign, :t, [:op, :rem], [:reg, :a], [:reg, :b]],
        [:assign, :a, [:reg, :b]],
        [:assign, :b, [:reg, :t]],
        [:goto, [:label, :test_b]],
        :gcd_done
    ]
    @gcd_vm = O::VM::Machine.create(%i(a b t), { rem: remainder, '=': equals }, controller)
    @gcd_vm.set_register_contents(:a, 206)
    @gcd_vm.set_register_contents(:b, 40)
    @gcd_vm.start
    @gcd_vm.get_register_contents(:a).must_equal 2
    @gcd_vm.get_register_contents(:b).must_equal 0
  end

end
