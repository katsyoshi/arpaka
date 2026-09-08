# frozen_string_literal: true

require "json"

module Lrama
  module Ruby
    module Languages
      module Ruby
        class Builder
          RULES = JSON.parse(File.read(File.expand_path("rules.json", __dir__)))
            .to_h { |rule| [rule.fetch("id"), rule.freeze] }.freeze
          private_constant :RULES

          def initialize
            @locals = {}
          end

          def program(statements)
            AST::Program.new(statements.freeze)
          end

          def integer(value)
            raise ArgumentError, "tINTEGER requires an Integer value" unless value.is_a?(Integer)
            AST::Literal.new(value)
          end

          def float(value)
            raise ArgumentError, "tFLOAT requires a Float value" unless value.is_a?(Float)
            AST::Literal.new(value)
          end

          def literal(value)
            AST::Literal.new(value)
          end

          def binary(operator, left, right)
            AST::Binary.new(operator, left, right)
          end

          def unary(operator, operand)
            AST::Unary.new(operator, operand)
          end

          def if_node(condition, then_body, else_body)
            AST::If.new(condition, then_body, else_body)
          end

          def unless_node(condition, then_body, else_body)
            AST::If.new(AST::Unary.new(:!, condition), then_body, else_body)
          end

          def elsif_node(condition, then_body, else_body)
            AST::If.new(condition, then_body, else_body)
          end

          def parentheses(statements, rule_id)
            unsupported(rule_id) unless statements.length == 1
            statements.first
          end

          def identifier(value)
            unless value.is_a?(Symbol) || value.is_a?(String)
              raise ArgumentError, "tIDENTIFIER requires a Symbol or String value"
            end
            value.to_sym
          end

          def declare_local(name)
            @locals[name] = true
            name
          end

          def read_local(name)
            (@locals.key?(name) ? AST::LocalRead : AST::BareCall).new(name)
          end

          def assign(name, value)
            AST::LocalWrite.new(name, value)
          end

          def array(elements)
            AST::ArrayLiteral.new(elements.freeze)
          end

          def hash(pairs)
            AST::HashLiteral.new(pairs.freeze)
          end

          def pair(key, value)
            AST::Pair.new(key, value)
          end

          def append(list, value)
            value.nil? ? list : (list + [value]).freeze
          end

          def unsupported(id)
            rule = RULES.fetch(id)
            raise UnsupportedSyntax.new(rule.fetch("rule"), rule.fetch("line"))
          end
        end
        private_constant :Builder
      end
    end
  end
end
