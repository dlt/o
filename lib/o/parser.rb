require 'parslet'

module O
  class ASTBuilder < Parslet::Transform
    rule(integer: simple(:x))  { { integer: Integer(x) } }
    rule(string:  simple(:x))  { { string:  String(x)  } }
    rule(boolean: simple(:x))  { { boolean: x == "#t"  } }
    rule(float:   simple(:x))  { { float:   Float(x)   } }
    rule(symbol:  simple(:x))  { { symbol:  x.to_sym   } }
    rule(funcall: subtree(:x)) do
      if x[:funcname][:symbol] == :if
        args = x[:args]
        { if: { test: args[0], conseq: args[1], alt: args[2] }}
      else
        { funcall: x }
      end
    end
  end

  class Parser < Parslet::Parser
    include Contracts

    root :expression

    rule(:expression) {
      boolean | string | symbol |  float | integer | funcall
    }

    rule(:funcall) {
      (
        left_paren >>
        space? >>
        symbol.as(:funcname) >>
        space? >>
        (expression >> space?).repeat(1).as(:args) >>
        space? >>
        right_paren
      ).as(:funcall)
    }

    rule(:left_paren)  { str("(") }
    rule(:right_paren) { str(")") }

    rule(:space) {
      match('\s').repeat(1)
    }

    rule(:space?) {
      space.maybe
    }

    rule(:symbol) {
      (match('[a-zA-Z=*-]|\+') >> match('[a-zA-Z=*_-]').repeat).as(:symbol) >> space?
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

    Contract String => Hash
    def parse(string)
      ASTBuilder.new.apply(super)
    rescue => error
      puts error.cause.ascii_tree
      raise error
    end
  end
end
