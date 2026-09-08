# frozen_string_literal: true

module Lrama
  module Ruby
    module Languages
      module Ruby
        module AST
          Program = Data.define(:statements)
          Literal = Data.define(:value)
          Binary = Data.define(:operator, :left, :right)
          Unary = Data.define(:operator, :operand)
          If = Data.define(:condition, :then_body, :else_body)
          LocalRead = Data.define(:name)
          LocalWrite = Data.define(:name, :value)
          BareCall = Data.define(:name)
          ArrayLiteral = Data.define(:elements)
          HashLiteral = Data.define(:pairs)
          Pair = Data.define(:key, :value)
          RangeLiteral = Data.define(:operator, :begin_value, :end_value)
          Ternary = Data.define(:condition, :then_value, :else_value)
          Call = Data.define(:name, :arguments)
          StringLiteral = Data.define(:value)
          Index = Data.define(:receiver, :arguments)
          Loop = Data.define(:kind, :condition, :body)
        end
      end
    end
  end
end
