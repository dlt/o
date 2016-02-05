module O
  include Contracts
  # A valid scheme value must be one of the following:
  SchemeValue = Or[Integer, Float, Bool, String, Symbol, Array, Proc]

  ASTNode = Hash
end
