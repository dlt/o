module O
  module VM
    class Register
      attr_reader :name
      attr_accessor :contents

      def initialize(name:, contents:)
        @name, @contents = name, contents
      end
    end

    class Machine
      include Contracts

      attr_reader :registers
      attr_reader :stack
      attr_reader :operations

      attr_accessor :instruction_sequence

      def self.create(register_names, operations, controller_text)
        new.tap do |machine|
          machine.allocate_registers(register_names)
          machine.install_operations(operations)
          machine.install_instruction_sequence(assemble(controller_text))
        end
      end

      def initialize
        @stack = []
        @instruction_sequence = []

        @pc = Register.new(name: :pc)
        @flag = Register.new(name: :flag)
        @operations = { initialize_stack: ->() { @stack.clear } }
      end

      def install_operations(operations)
        @operations = operations
      end

      def start
        @pc.contents = @instruction_sequence
        execute
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

      Contract Symbol => Bool
      def allocate_register(name)
        registers.update(name => Register.new(name: name, contents: nil))
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

      Contract Symbol => Register
      def lookup_register(register_name)
        registers.fetch(register_name)
      rescue
        raise "Invalid register name #{register_name}"
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

      def allocate_default_registers
        @registers ||= {
          pc:   @pc,
          flag: @flag
        }
      end
    end
  end
end
