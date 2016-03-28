require 'test_helper'

describe O::VM do
  before do
    @controller = nil
    @vm = O::VM::Machine.new([:regname1, :regname2], [], [])
    equals = ->(a, b) { a == b }
    remainder = -> (a, b) { a % b }
    controller = [
      :'test-b',
        [:test, [:op, :'='], [:reg, :b], [:const, 0]],
        [:branch, [:label, :gcd_one]],
    ]
    @gcd_vm = O::VM::Machine.new(%i(a b t), { rem: remainder, '=': equals }, controller)
  end

  it 'should parse an int' do
    @vm.set_register_contents(:regname1, 1).must_equal true
    @vm.get_register_contents(:regname1).must_equal 1

    @vm.set_register_contents(:regname2, 2).must_equal true
    @vm.get_register_contents(:regname2).must_equal 2

  end

end
