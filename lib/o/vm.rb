module O
  module VM
    class Register
      attr_reader :name
      attr_accessor :contents

      def initialize(name, contents = nil)
        @name, @contents = name, contents
      end
    end

    class Assembler
      def initialize(machine, controller_text)
        @machine, @controller_text = machine, controller_text
      end

      def assemble
      end

      def extract_labels(text)
        text.map do |instruction|
        end
      end

      def update_instructions
      end
    end

    Instruction = Class.new(Struct.new(:text, :instruction))

    class Machine
      include Contracts

      attr_reader :registers, :stack

      attr_accessor :instruction_sequence, :operations

      def self.create(register_names, operations, controller_text)
        new.tap do |machine|
          machine.allocate_registers(register_names)
          machine.operations = operations
          machine.instruction_sequence = machine.assemble(controller_text)
        end
      end

      def assemble(text)
      end

      def update_instructions(instructions, labels)
        instructions.each do |inst|
          inst.instruction = make_execution_procedure(inst.text, labels, machine)
        end
      end

      def initialize
        @stack, @instruction_sequence = [], []

        @pc, @flag  = Register.new(:pc), Register.new(:flag)
        @operations = {initialize_stack: -> { @stack.clear }}
      end

      def start
        @pc.contents = @instruction_sequence
        execute
      end

      Contract Symbol => Bool
      def allocate_register(name)
        registers.merge!(name => Register.new(name))
        true
      rescue
        false
      end

      Contract Symbol => Register
      def lookup_register(register_name)
        registers.fetch(register_name)
      rescue
        raise "Invalid register name #{register_name}"
      end

      def execute
        insts = @pc.contents
        if insts.nil? or insts.empty?
          :done
        else
          instruction_execution_procedure(insts.first).execute
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
        if registers.keys.include?(register_name)
          registers.fetch(register_name).contents = value
          true
        else
          false
        end
      end

      def registers
        @registers ||= {pc: @pc, flag: @flag}
      end
    end
  end
end
