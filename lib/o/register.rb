module O
  module VM
    class Register
      attr_reader :name
      attr_accessor :contents

      def initialize(name:, contents:)
        @name, @contents = name, contents
      end
    end
  end
end
