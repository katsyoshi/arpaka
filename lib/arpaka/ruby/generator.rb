# frozen_string_literal: true

require_relative "grammar"
require_relative "class_name_parser"
require_relative "frontend_emitter"

module Arpaka::Ruby
  class Generator
    def generate(ruby_source: nil, parse_y: nil, class_name:, ast_type: :detailed,
      runtime_bundle: nil)
      if ruby_source.nil? == parse_y.nil?
        raise ::Arpaka::Error, "specify exactly one of ruby_source or parse_y"
      end
      ast_type = case ast_type.to_s
      when "detailed" then :detailed
      when "structured" then :structured
      else
        raise ::Arpaka::Error, "ast_type must be detailed or structured"
      end
      runtime_bundle ||= ast_type == :structured ?
        FrontendEmitter::STRUCTURED_RUNTIME_BUNDLE : FrontendEmitter::DETAILED_RUNTIME_BUNDLE
      class_name = ClassNameParser.parse(class_name)
      unless ::Ruby::Box.enabled?
        raise ::Arpaka::Error, "Ruby Box is required for generation. Start Ruby with RUBY_BOX=1."
      end
      artifacts = Grammar.artifacts(ruby_source: ruby_source, parse_y: parse_y)
      grammar_filename = parse_y || File.join(ruby_source, "parse.y")
      parser = Lrama::Ruby.generate(artifacts.fetch("parse.y"),
        filename: grammar_filename, class_name: "Parser", allow_error_rules: true)
      parser = parser.delete_prefix("# frozen_string_literal: true\n")
      FrontendEmitter.new.emit(parser: parser, artifacts: artifacts, class_name: class_name,
        grammar_filename: grammar_filename, ruby_source: ruby_source, runtime_bundle: runtime_bundle,
        ast_type: ast_type)
    rescue SyntaxError => error
      raise ::Arpaka::Error, "Invalid generated frontend: #{error.message}"
    rescue SystemCallError => error
      raise ::Arpaka::Error, "Cannot read Ruby frontend inputs: #{error.message}"
    end

  end
end
