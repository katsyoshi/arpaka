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
          LocalRead = Data.define(:name)
          LocalWrite = Data.define(:name, :value)
          BareCall = Data.define(:name)
        end
      end
    end
  end
end
