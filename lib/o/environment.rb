module O
  class Environment
    extend Forwardable
    include Contracts

    SchemeValue = Or[Integer, Float, Bool, String, Symbol, Array, Proc]

    def_delegators :@symbol_table, :keys, :update, :[], :key?

    def initialize(symbol_table = {}, outer = {})
      @symbol_table = symbol_table
      @outer = outer
    end

    Contract ArrayOf[Symbol], ArrayOf[SchemeValue] => Environment
    def extended_environment(formal_params, args)
      Environment.new(Hash[formal_params.zip(args)], self)
    end

    Contract Symbol => SchemeValue
    def fetch(symbol)
      @symbol_table[symbol] or @outer.fetch(symbol)
    rescue
      raise Exception.new "no such variable #{symbol}"
    end

  end
end
