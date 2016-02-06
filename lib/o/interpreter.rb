module O
  # A very simple scheme interpreter that aims to be R3RS compatible.
  class Interpreter
    include Contracts

    # Top level environment containing builtin functions
    attr_reader :top_level_environment

    def initialize
      @top_level_environment = Environment.new \
        :"+"  => -> (*args) { Array(args).inject(0) { |s, v| s + v } },
        :"*"  => -> (*args) { Array(args).inject(1) { |p, v| p * v } },
        :"-"  => -> (*args) { args = Array(args); total = args.shift; args.each { |a| total -= a }; total },
        :"/"  => -> (*args) { args = Array(args).inject { |p, v| p / v } },
        :"="  => -> (a, b)  { a == b  },
        :">"  => -> (a, b)  { a > b  },
        :"<"  => -> (a, b)  { a < b  },
        :"<=" => -> (a, b)  { a <= b  },
        :">=" => -> (a, b)  { a >= b  },
        not:     -> (a)     { not a },
        or:      -> (a, b)  { a or b },
        and:     -> (a, b)  { a and b },
        list:    -> (*args) { Array(args) }
    end

    # Evaluates a string containing scheme code and evaluates it.
    #
    # @param [String] string a string containing scheme code.
    # @return [SchemeValue]
    Contract String => SchemeValue
    def eval(string)
      eval_ast(Parser.new.parse(string), top_level_environment)
    end

    private
    # Evaluates the AST and returns a scheme value.
    #
    # @param [Hash] ast_node the AST node to be evaluated.
    # @param [Environment] env the enviroment used as context for AST evaluation.
    # @return [SchemeValue]
    Contract ASTNode, Environment => SchemeValue
    def eval_ast(ast_node, env)
      case node_type = ast_node.keys.first

      # when node represents a self-evaluating expression, just return the expression value.
      when :integer, :boolean, :string, :float
        ast_node[node_type]

      when :symbol
        symbol_expression = ast_node[node_type]
        env.fetch(symbol_expression)

      # when node is a if expression, return its conseq or alternate part depending on
      # the result of the evaluation of its test part.
      when :if
        if_expression     = ast_node[node_type]
        test, conseq, alt = if_expression.values_at(:test, :conseq, :alt)

        eval_ast(test, env) ? eval_ast(conseq, env) : eval_ast(alt, env)

      when :begin
        begin_expression = ast_node[node_type]
        begin_expression[:exps].map { |exp| eval_ast(exp, env) }.last

      when :set!
        set_expression = ast_node[node_type]
        varname, exp   = set_expression.values_at(:varname, :exp)

        eval_ast(exp, env).tap do |val|
          env.update(varname.fetch(:symbol) => val)
        end

      when :cond
        cond_expression = ast_node[node_type]
        cond_expression.each do |clause|
          if clause.key?(:else)
            return eval_ast(clause[:else][:else_result], env)
          elsif eval_ast(clause, env)
            return eval_ast(clause[:result], env)
          end
        end

      when :let, :"let*"
        let_expression = ast_node[node_type]
        bindings, body = let_expression.values_at(:bindings, :body)
        new_env        = {}

        bindings.each do |binding|
          name = binding[:name][:symbol]
          val  = if node_type == :let
            eval_ast(binding[:val], env)
          else
            eval_ast(binding[:val], Environment.new(new_env, env))
          end
          new_env.update(name => val)
        end

        eval_ast(create_begin(body), Environment.new(new_env, env))

      # when node is a function call:
      # - get the procedure associated to the funcname symbol;
      # - get the args;
      # - evaluate the args and apply the function the values returned in these evaluations as arguments.
      when :funcall
        funcall_exp = ast_node[node_type]
        apply(funcall_exp, env)
      end
    end

    # Checks if the symbol passed as argument is the name of a build in
    # procedure.
    #
    # @param [Symbol] symbol
    # @return [Bool]
    Contract Symbol => Bool
    def builtin_procedure?(symbol)
      top_level_environment.keys.member?(symbol)
    end

    # Given a symbol containing a vaid built-in procedure name,
    # return the correspoding Proc that defines the built-in.
    #
    # @param [Symbol] symbol the name of the builtin-procedure
    # @return [Proc]
    Contract Symbol => Proc
    def get_builtin_procedure(symbol)
      top_level_environment.fetch(symbol)
    end

    Contract ASTNode, Environment => SchemeValue
    def apply(funcall_exp, env)
      if funcall_exp.key?(:funcname)
        funcname = funcall_exp[:funcname][:symbol]
        builtin_procedure?(funcname) or raise "Invalid builtin procedure: #{funcname}"

        args      = funcall_exp[:args]
        procedure = get_builtin_procedure(funcname)
        arguments = args.map { |a| eval_ast(a, env) }
        procedure.call(*arguments)

      elsif funcall_exp.key?(:lambda)
        apply_compound_procedure(funcall_exp, env)
      end
    end

    Contract ASTNode, Environment => SchemeValue
    def apply_compound_procedure(lambda_exp, env)
      params, body = lambda_exp[:lambda].values_at(:formal_params, :lambda_body)
      args         = lambda_exp[:args].map { |e| eval_ast(e, env) }
      params       = params.map { |p| p[:symbol] }

      eval_ast(create_begin(body), Environment.new(Hash[params.zip(args)], env))
    end

    Contract ASTNode => ASTNode
    def create_begin(body)
      { begin: { exps: [body] } }
    end
  end
end
