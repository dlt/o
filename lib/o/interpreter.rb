module O
  class Interpreter
    include Contracts
    SchemeValue = Or[Integer, Float, Bool, String, Symbol, Array]

    Contract String => SchemeValue
    def eval(string)
      eval_ast(Parser.new.parse(string))
    end

    Contract Hash => SchemeValue
    def eval_ast(ast_node)
      case node_type = ast_node.keys.first
      when :integer, :boolean, :symbol, :string, :float
        ast_node[node_type]
      when :if
        if_expression = ast_node[node_type]
        if eval_ast(if_expression[:test])
          eval_ast(if_expression[:conseq])
        else
          eval_ast(if_expression[:alt])
        end
      when :funcall
        funcname = ast_node[:funcall][:funcname][:symbol]
        args = ast_node[:funcall][:args].map { |a| eval_ast(a) }
        if builtin_procedure?(funcname)
          fun = get_builtin_procedure(funcname)
          fun.call(*args)
        end
      end
    end

    Contract Symbol => Bool
    def builtin_procedure?(symbol)
      %i(list + *).member?(symbol)
    end

    Contract Symbol => Bool
    def special_form?(symbol)
      %i(if).member?(symbol)
    end

    Contract Symbol => Proc
    def get_builtin_procedure(symbol)
      {
        :"+" => -> (*args) { Array(args).inject(0) {|s, v| s + v } },
        :"*" => -> (*args) { Array(args).inject(1) {|p, v| p * v } },
        list:   -> (*args) { Array(args) },
      }.fetch(symbol)
    end
  end
end
