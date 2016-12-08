require 'pp'

def cons(a, list)
  [a].concat(list)
end

class Array
  def cdr
    self[1..-1]
  end

  def car
    first
  end
end

module O
  module VM
    class Register
      attr_reader :name
      attr_accessor :contents

      def initialize(name)
        @name     = name
        @contents = '*unassigned*'
      end
    end

    class Assembler
      attr_reader :machine
      def initialize(machine, controller_text)
        @machine         = machine
        @controller_text = controller_text
      end

      def assemble
        extract_labels(@controller_text) do |insts, labels|
          update_instructions(insts, labels)
        end
      end

      def extract_labels(text, &receive)
        if text.empty?
          receive.call([], {})
        else
          extract_labels(text.cdr) do |insts, labels|
            next_inst = text.car
            if next_inst.is_a? Symbol
              receive.call(insts, labels.merge(next_inst => insts))
            else
              receive.call(cons(make_instruction_text(next_inst), insts), labels)
            end
          end
        end
      end

      def make_instruction_text(text)
        cons(text, [])
      end

      def instruction_text_inst(inst)
        inst.car
      end

      def instruction_text_proc(inst)
        inst.cdr
      end

      def set_instruction_execution_proc(inst, procedure)
        inst[1] = procedure
      end

      def update_instructions(instructions, labels)
        instructions.map do |inst|
          execution_procedure = make_execution_procedure(inst.car, labels)
          set_cdr!(inst, execution_procedure)
        end
      end

      def make_execution_procedure(inst, labels)
        case inst.car.to_sym
        when :assign
          make_assign(inst)
        when :test
          make_test(inst)
        when :branch
          make_branch(inst, labels)
        when :goto
          make_goto(inst, labels)
        when :save
          make_save(inst)
        when :restore
          make_restore(inst)
        when :perform
          make_perform(inst)
        else
          raise "fuck #{inst}"
        end
      end

      def make_save(inst)
        register = machine.get_register(stack_inst_reg_name(inst))
        lambda do
          machine.stack_push(reg.contents)
          machine.advance_pc
        end
      end

      def make_restore(inst)
        register = machine.get_register(stack_inst_reg_name(inst))
        lambda do
          reg.contents = machine.stack_pop
          machine.advance_pc
        end
      end

      def make_perform(inst)
        action = perform_action(inst)
        if operation_exp?(action)
          action_proc = make_operation_expression(action)
          lambda do
            action_proc.call
            machine.advance_pc
          end
        else
          raise "Bad PERFORM instruction -- ASSEMBLE #{inst}"
        end
      end

      def perform_action(inst)
        inst.cdr
      end

      def make_assign(inst)
        target = machine.get_register(assign_reg_name(inst))
        value_exp = assign_value_exp(inst)

        value_proc = if operation_exp?(value_exp)
          make_operation_expression(value_exp)
        else
          make_primitive_expression(value_exp.car)
        end

        proc do
          target.contents = value_proc.call
          machine.advance_pc
        end
      end

      def make_branch(inst, labels)
        dest = branch_dest(inst)
        if label_expression?(dest)
          insts = labels.fetch(label_expression_label(dest))
          lambda do
            if machine.get_register_contents(:flag)
              machine.set_register_contents(:pc, insts)
            else
              machine.advance_pc
            end
          end
        else
          raise "Bad BRANCH instruction -- ASSEMBLE #{inst}"
        end
      end

      def make_goto(inst, labels)
        dest = goto_dest(inst)
        if label_expression?(dest)
          insts = labels.fetch(label_expression_label(dest))
          lambda do
            machine.set_register_contents(:pc, insts)
          end
        elsif register_expression?(dest)
          reg = machine.get_register(register_expression_reg(dest))
          lambda do
            machine.set_register_contents(:pc, reg.contents)
          end
        else
          raise "Bad GOTO instruction #{inst}"
        end
      end

      def make_test(inst)
        condition = test_condition(inst)
        if operation_exp?(condition)
          condition_proc = make_operation_expression(condition)
          lambda do
            machine.get_register(:flag).contents = condition_proc.call
            machine.advance_pc
          end
        else
          raise "Bad TEST instruction -- ASSEMBLE #{inst}"
        end
      end

      def make_primitive_expression(exp)
        if constant_expression?(exp)
          lambda do
            constant_expression_value(exp)
          end
        elsif label_expression?(exp)
          insts = labels.fecth(label_expression_label(exp))
          lambda do
            insts
          end
        elsif register_expression?(exp)
          register = machine.lookup_register(register_expression_reg(exp))
          lambda do
            register.contents
          end
        else
          raise "Unknown expression type -- ASSEMBLE #{exp}"
        end
      end

      def branch_dest(inst)
        inst[1]
      end

      def goto_dest(inst)
        inst[1]
      end

      def assign_reg_name(assign_inst)
        assign_inst[1]
      end

      def stack_inst_reg_name(inst)
        inst[1]
      end

      def assign_value_exp(assign_inst)
        assign_inst.cdr.cdr
      end

      def operation_exp?(exp)
        exp.is_a?(Array) and tagged_list?(exp.car, :op)
      end

      def operation_expression_op(exp)
        exp.car[1]
      end

      def tagged_list?(exp, op)
        exp.first == op
      end

      def set_cdr!(list, val)
        while list.size > 1
          list.pop
        end
        list.push(val)
      end

      def test_condition(inst)
        inst.cdr
      end

      def constant_expression?(exp)
        tagged_list?(exp, :const)
      end

      def constant_expression_value(exp)
        exp[1]
      end

      def register_expression?(exp)
        tagged_list?(exp, :reg)
      end

      def register_expression_reg(exp)
        exp[1]
      end

      def label_expression?(exp)
        tagged_list?(exp, :label)
      end

      def label_expression_label(exp)
        exp[1]
      end

      def lookup_prim(op)
        @machine.operations[op]
      end

      def operation_expression_operands(exp)
        exp.cdr
      end

      def make_operation_expression(exp)
        op = lookup_prim(operation_expression_op(exp))
        aprocs = operation_expression_operands(exp).map { |e| make_primitive_expression(e) }
        lambda do
          op.call(*aprocs.map { |a| a.call })
        end
      end
    end

    class Machine
      include Contracts

      attr_reader :register_table, :stack, :pc, :flag
      attr_accessor :instruction_sequence, :operations

      def self.create(register_names, operations, controller_text)
        new.tap do |machine|
          machine.allocate_registers(register_names)
          machine.operations = operations
          machine.instruction_sequence = machine.assemble(controller_text)
        end
      end

      def initialize
        @stack                = []
        @instruction_sequence = []
        @pc                   = Register.new(:pc)
        @flag                 = Register.new(:flag)
        @register_table       = {pc: @pc, flag: @flag}
        @operations           = {initialize_stack: -> { @stack.clear }}
      end

      def assemble(controller_text)
        Assembler.new(self, controller_text).assemble
      end

      def install_operations(ops)
        @operations.merge!(ops)
      end

      def advance_pc
        @pc.contents = @pc.contents.cdr
      end

      def start
        @pc.contents = @instruction_sequence
        execute
      end

      def install_instruction_sequence(seq)
        @instruction_sequence = seq
      end

      def stack_push(val)
        @stack.push(val)
      end

      def stack_pop
        @stack.pop
      end

      Contract Symbol => Bool
      def allocate_register(name)
        register_table.merge!(name => Register.new(name))
        true
      rescue
        false
      end

      Contract Symbol => Register
      def lookup_register(register_name)
        register_table.fetch(register_name)
      rescue
        raise "Invalid register name #{register_name}"
      end
      alias_method :get_register, :lookup_register

      def execute
        insts = @pc.contents
        if insts.nil? or insts.empty?
          :done
        else
          insts.first.last.call
          execute
        end
      end

      Contract ArrayOf[Symbol] => Bool
      def allocate_registers(register_names)
        register_names.each do |name|
          allocate_register(name)
        end
        true
      end

      Contract Symbol => SchemeValue
      def get_register_contents(register_name)
        lookup_register(register_name).contents
      end

      Contract Symbol, SchemeValue => Bool
      def set_register_contents(register_name, value)
        if register_table.keys.include?(register_name)
          register_table.fetch(register_name).contents = value
          true
        else
          false
        end
      end

      def inspect
        "<#Machine pc=#{pc} flag='#{flag}' stack='#{stack}'>"
      end
    end
  end
end
