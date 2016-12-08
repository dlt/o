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

  it 'should just do it' do
    registers = %i(the_cars the_cdrs new free scan old root)
    operations = {
      vector_set: ->(a, i) { a[i] },
      vector_set: -> (a , i, v) { a[i] = v },
      equals: -> (a, b) { a == b },
      '+': -> (a, b) { a + b },
    }
    controller = [
      :begin_gargabe_collection,
        [:assign, :free, [:const 0]],
        [:assign, :scan, [:const 0]],
        [:assign, :old, [:reg :root]],
        [:assign, :rellocate_continue, [:label :reassign_root]],
        [:goto, [:label, :rellocate_old_result_in_new]],
      :reassign_root,
        [:assign, :root, [:reg, :new]],
        [:goto [:label, :gc_loop]],
      :gc_loop,
        [:test, [:op, :test], [:reg, :scan], [:reg, :free]],
        [:branch, [:label, :gc_flip]],
        [:assign, :old, [:op, :vector_ref], [:reg, :new_cars], [:reg, :scan]],
        [:assign, :rellocate_continue, [:label, :update_car]],
        [:goto, [:label, :rellocate_old_result_in_new]],
      :update_car,
        [:perform, [:op, :vector_set], [:reg, :new_cdrs], [:reg, :scan], [:reg, :new]],
        [:assign, :scan, [:op, :'+'], [:reg, :scan], [:const, 1]],
        [:goto [:label, :gc_loop]],
      :rellocate_old_result_in_new,
        [:test, [:op, :pointer_to_pair?], [:reg, :old]],
        [:branch, [:label, :pair]],
        [:assign, :new, [:reg, :old]],
        [:goto, [:reg, :rellocate_continue]],
      :pair,
        [:assign, :oldcr, [:op, :vector_ref], [:reg, :the_cars], [:reg, :old]],
        [:branch, [:label, :pair]],
        [:test, [:op, :broken_heart?], [:reg, :oldcr]],
        [:branch, [:label, :already_moved]],
        [:assign, :new, [:reg, :free]],
        [:assign, :free, [:op, :'+'], [:reg, :free], [:const, 1]],
        [:perform, [:op, :vector_set], [:reg, :new_cars], [:reg, :new], [:reg, :oldcr]],
        [:assign, :oldcr, [:op, :vector_ref], [:reg, :the_cdrs], [:reg, :old]],
        [:perform, [:op, :vector_set], [:reg, :new_cdrs], [:reg, :new], [:reg, :oldcr]],
        [:perform, [:op, :vector_set], [:reg, :the_cars], [:reg, :old], [:reg, :broken_heart]],
        [:perform, [:op, :vector_set], [:reg, :the_cdrs], [:reg, :old], [:reg, :new]],
        [:goto, [:reg, :rellocate_continue]],
      :already_moved,
        [:assign, :new, [:op, :vector_ref], [:reg, :the_cdrs], [:reg, :old]],
        [:goto, [:reg, :rellocate_continue]],
      :gc_flip,
        [:assign, :temp, [:reg, :the_cdrs]],
        [:assign, :the_cdrs, [:reg, :new_cdrs]],
        [:assign, :new_cdrs, [:reg, :temp]],
        [:assign, :temp, [:reg, :the_cars]],
        [:assign, :the_cars, [:reg, :new_cars]],
        [:assign, :new_cars, [:reg, :temp]],
    ]
    @vm = O::VM::Machine.create(registers, operations, controller)
    @vm.set_register_contents(:a, 206)
    @vm.set_register_contents(:b, 40)
    @vm.start
    @vm.get_register_contents(:a).must_equal 2
    @vm.get_register_contents(:b).must_equal 0
  end

end
