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

          def operator(value)
            value.to_sym
          end

          def range(operator, begin_value, end_value)
            AST::RangeLiteral.new(operator, begin_value, end_value)
          end

          def ternary(condition, then_value, else_value)
            AST::Ternary.new(condition, then_value, else_value)
          end

          def call(name, arguments)
            AST::Call.new(name, arguments.freeze)
          end

          def string(value)
            AST::StringLiteral.new(value.to_s)
          end

          def regexp(value)
            AST::RegexpLiteral.new(value.to_s)
          end

          def xstring(value)
            AST::XStringLiteral.new(value.to_s)
          end

          def for_node(variable, enumerable, body)
            AST::For.new(variable, enumerable, body)
          end

          def def_node(name, arguments, body)
            AST::Def.new(name.to_sym, (arguments || []).freeze, body || [].freeze)
          end

          def class_node(name, superclass, body)
            AST::ClassDef.new(name.to_sym, superclass, body_nodes(body))
          end

          def module_node(name, body)
            AST::ModuleDef.new(name.to_sym, body_nodes(body))
          end

          def body_nodes(body)
            value = body
            while value.is_a?(Array) && value.length == 1 && value.first.is_a?(Array)
              value = value.first
            end
            value || [].freeze
          end

          def symbol(value)
            AST::Literal.new(value.to_sym)
          end

          def join_strings(parts)
            parts.join
          end

          def concat_strings(left, right)
            AST::StringLiteral.new(left.value + right.value)
          end

          def index(receiver, arguments)
            AST::Index.new(receiver, arguments.freeze)
          end

          def loop(kind, condition, body)
            AST::Loop.new(kind, condition, body)
          end

          def control(kind)
            AST::Control.new(kind)
          end

          def variable(kind, name)
            AST::Variable.new(kind, name.is_a?(String) ? name.to_sym : name)
          end

          def rescue_modifier(expression, fallback)
            AST::Rescue.new(expression, fallback)
          end

          def when_node(patterns, body)
            AST::When.new(patterns.freeze, body)
          end

          def case_node(expression, whens, else_body)
            AST::Case.new(expression, whens.freeze, else_body)
          end

          def case_clauses(value)
            value.is_a?(Array) ? value : [value]
          end

          def case_parts(value)
            values = case_clauses(value)
            if values.all? { |item| item.is_a?(AST::When) }
              [values, nil]
            else
              [values.grep(AST::When), values.reject { |item| item.is_a?(AST::When) }]
            end
          end

          def case_chain(when_node, rest)
            [when_node] + (rest.nil? ? [] : case_clauses(rest))
          end

          def lambda_node(arguments, body)
            AST::Lambda.new((arguments || []).freeze, body_nodes(body))
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
            return name if name.is_a?(AST::Variable)
            (@locals.key?(name) ? AST::LocalRead : AST::BareCall).new(name)
          end

          def assign(name, value)
            AST::LocalWrite.new(name, value)
          end

          def array(elements)
            AST::ArrayLiteral.new(elements.freeze)
          end

          def word_array(elements, symbols: false)
            values = elements.map { |value| symbols ? value.to_sym : AST::StringLiteral.new(value.to_s) }
            AST::ArrayLiteral.new(values.freeze)
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
