module O
  class Environment
    extend Forwardable

    def_delegators :@symbol_table, :fetch, :keys

    def initialize(symbol_table)
      @symbol_table = symbol_table
    end
  end
end
