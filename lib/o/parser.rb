require 'parslet'

module O
  class ASTBuilder < Parslet::Transform
    rule(integer: simple(:x))  { { integer: Integer(x) } }
    rule(string:  simple(:x))  { { string:  String(x)  } }
    rule(boolean: simple(:x))  { { boolean: x == "#t"  } }
    rule(float:   simple(:x))  { { float:   Float(x)   } }
    rule(symbol:  simple(:x))  { { symbol:  x.to_sym   } }
    rule(funcall: subtree(:x)) do
      if x.key?(:funcname)
        args = x[:args]
        case x[:funcname][:symbol]
        when :if
          {
            if: {
              test: args[0],
              conseq: args[1],
              alt: args[2]
            }
          }

        when :begin
          {
            begin: {
              exps: args
            }
          }
        when :set!, :define
          {
            set!: {
              varname: args.first,
              exp: args.last
            }
          }
        else
          { funcall: x }
        end
      else
        { funcall: x }
      end
    end
  end

  class Parser < Parslet::Parser
    include Contracts

    root :expression

    rule(:expression) {
      boolean |
      string  |
      symbol  |
      float   |
      integer |
      lambdacall |
      funcall |
      lambda_exp
    }

    rule(:space) {
      match('\s').repeat(1)
    }

    rule(:space?) {
      space.maybe
    }

    rule(:left_paren)  { str("(") }

    rule(:right_paren) { str(")") }

    rule(:symbol) {
      (match('[a-zA-Z=*-/]|\+') >> match('[a-zA-Z=*_-]|!').repeat).as(:symbol) >> space?
    }

    rule(:integer) {
      ((str('+') | str('-')).maybe >> match("[0-9]").repeat(1)).as(:integer) >> space?
    }

    rule(:float) {
      (match('[0-9]') >> (str('.') >> match('[0-9]').repeat(1))).as(:float)
    }

    rule(:string) {
      str('"') >> (
        str('\\') >> str('"') |
        str('"').absent? >> any
      ).repeat.as(:string) >> str('"') >> space?
    }

    rule(:boolean) {
      (str("#f") | str("#t")).as(:boolean)
    }

    rule(:funcall) {
      (
        left_paren >>
        space? >>
        symbol.as(:funcname) >>
        space? >>
        list_of_args.as(:args) >>
        space? >>
        right_paren
      ).as(:funcall)
    }

    rule(:list_of_args) {
      (expression >> space?).repeat(1)
    }

    rule(:lambda_exp) {
      (
        space? >>
        left_paren >>
        space? >>
        str("lambda") >>
        space? >>
        list_of_expressions.as(:formal_params) >>
        space? >>
        expression.as(:lambda_body) >>
        space? >>
        right_paren
      ).as(:lambda)
    }

    rule(:lambdacall) {
      (
        left_paren >>
        space? >>
        lambda_exp >>
        space? >>
        list_of_args.as(:args) >>
        space? >>
        right_paren
      ).as(:funcall)
    }

    rule(:list_of_expressions) {
      left_paren >> (expression >> space?).repeat(1) >> right_paren
    }

    Contract String => Hash
    def parse(string)
      ASTBuilder.new.apply(super)
    rescue => error
      puts error
      puts error.cause.ascii_tree
      raise error
    end
  end
end
