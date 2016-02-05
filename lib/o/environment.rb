module O
  class Environment
    extend Forwardable
    include Contracts

    def_delegators :@symbol_table, :keys, :update, :[], :key?

    def initialize(symbol_table = {}, outer = {})
      @symbol_table = symbol_table
      @outer = outer
    end

    Contract Symbol => SchemeValue
    def fetch(symbol)
      @symbol_table[symbol] or @outer.fetch(symbol)
    rescue
      raise Exception.new "no such variable #{symbol}"
    end

  end
end
