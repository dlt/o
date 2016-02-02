require 'parslet'
require 'pry'

module O
  class Parser < Parslet::Parser
    include Contracts::Core
    include Contracts::Builtin

    class TreeBuilder < Parslet::Transform
      rule(:integer => simple(:x)) { { integer: Integer(x) } }
      rule(:string  => simple(:x)) { { string: String(x) } }
    end

    root :expression

    rule(:expression) {
      integer | string
    }

    rule(:body) {
      (expression | identifier | float | integer | string).repeat.as(:exp)
    }

    rule(:space) {
      match('\s').repeat(1)
    }
    rule(:space?) {
      space.maybe
    }

    rule(:identifier) {
      (match('[a-zA-Z=*]') >> match('[a-zA-Z=*_]').repeat).as(:identifier) >> space?
    }

    rule(:float) {
      (
        integer >> (
          str('.') >> match('[0-9]').repeat(1) |
          str('e') >> match('[0-9]').repeat(1)
        ).as(:e)
      ).as(:float) >> space?
    }

    rule(:integer) {
      ((str('+') | str('-')).maybe >> match("[0-9]").repeat(1)).as(:integer) >> space?
    }

    rule(:string) {
      str('"') >> (
        str('\\') >> str('"') |
        str('"').absent? >> any
      ).repeat.as(:string) >> str('"') >> space?
    }

    Contract String => Hash
    def parse string
      TreeBuilder.new.apply super
    rescue => error
      puts error.cause.ascii_tree
      raise error
    end
  end
end
