module O
  # A very simple scheme interpreter that aims to be R3RS compatible.
  class Interpreter
    include Contracts

    # A valid scheme value must be one of the following:
    SchemeValue = Or[Integer, Float, Bool, String, Symbol, Array]

    # Evaluates a string containing scheme code and evaluates it.
    #
    # @param [String] string a string containing scheme code.
    # @return [SchemeValue]
    Contract String => SchemeValue
    def eval(string)
      eval_ast(Parser.new.parse(string))
    end

    private
    # Evaluates the AST and returns a scheme value.
    #
    # @param [Hash] ast_node the AST node to be evaluated.
    # @return [SchemeValue]
    Contract Hash => SchemeValue
    def eval_ast(ast_node)
      case node_type = ast_node.keys.first

      # when node represents a self-evaluating expression, just return the expression value.
      when :integer, :boolean, :symbol, :string, :float
        ast_node[node_type]

      # when node is a if expression, return its conseq or alternate part depending on
      # the result of the evaluation of its test part.
      when :if
        if_expression = ast_node[node_type]

        if eval_ast(if_expression[:test])
          eval_ast(if_expression[:conseq])
        else
          eval_ast(if_expression[:alt])
        end

      # when node is a function call:
      # - get the procedure associated to the funcname symbol;
      # - get the args;
      # - evaluate the args and apply the function the values returned in these evaluations as arguments.
      when :funcall
        funcname = ast_node[:funcall][:funcname][:symbol]
        args = ast_node[:funcall][:args]

        if builtin_procedure?(funcname)
          fun = get_builtin_procedure(funcname)
          fun.call(*args.map { |a| eval_ast(a) })
        end
      end
    end

    # Checks if the symbol passed as argument is the name of a build in
    # procedure.
    #
    # @param [Symbol] symbol
    # @return [Bool]
    Contract Symbol => Bool
    def builtin_procedure?(symbol)
      %i(list + * - /).member?(symbol)
    end

    # Given a symbol containing a vaid built-in procedure name,
    # return the correspoding Proc that defines the built-in.
    #
    # @param [Symbol] symbol the name of the builtin-procedure
    # @return [Proc]
    Contract Symbol => Proc
    def get_builtin_procedure(symbol)
      {
        :"+" => -> (*args) { Array(args).inject(0) {|s, v| s + v } },
        :"*" => -> (*args) { Array(args).inject(1) {|p, v| p * v } },
        :"-" => -> (*args) { args = Array(args); total = args.shift; args.each { |a| total -= a }; total },
        :"/" => -> (*args) { args = Array(args).inject { |p, v| p / v } },
        list:   -> (*args) { Array(args) },
      }.fetch(symbol)
    end
  end
end
