module O
  class Interpreter
    include Contracts

    Contract String => Or[Integer, Float, String, Symbol, Array]
    def eval(string)
      eval_ast(Parser.new.parse(string))
    end

    Contract Hash => Or[Integer, Float, String, Symbol, Array]
    def eval_ast(ast)
      case ast.keys.first
      when :integer, :boolean, :symbol, :string, :float
        ast[ast.keys.first]
      when :funcall
        funcname = ast[:funcall][:funcname][:symbol]
        args = ast[:funcall][:args].map { |a| eval_ast(a) }

        if builtin_procedure?(funcname)
          fun = get_builtin_procedure(funcname)
          fun.call(*args)
        end
      end
    end

    Contract Symbol => Bool
    def builtin_procedure?(symbol)
      %i(list + *).member? symbol
    end

    Contract Symbol => Proc
    def get_builtin_procedure(symbol)
      {
        :"+" => -> (*args) { Array(args).inject(0) {|p, v| p + v } },
        :"*" => -> (*args) { Array(args).inject(1) {|p, v| p * v } },
        list:   -> (*args) { Array(args) },
      }.fetch(symbol)
    end
  end
end
