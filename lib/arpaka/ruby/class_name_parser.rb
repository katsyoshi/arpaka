# frozen_string_literal: true

module Arpaka::Ruby
  class ClassName
    attr_reader :components

    def initialize(components)
      @components = components.freeze
      freeze
    end

    def namespaces
      components[0...-1]
    end

    def constant
      components.last
    end

    def resolve(root)
      components.reduce(root) { |namespace, name| namespace.const_get(name, false) }
    end

    def to_s
      components.join("::")
    end
  end

  class ClassNameParser
    def self.parse(value)
      new(value).parse
    end

    def initialize(value)
      @value = value
      @index = 0
      @components = []
    end

    def parse
      unless @value.is_a?(String)
        invalid("must be a String")
      end

      parse_component
      until end_of_input?
        parse_separator
        parse_component
      end
      ClassName.new(@components)
    end

    private

    def parse_component
      component_number = @components.length + 1
      if end_of_input? || current_byte == 58
        invalid("component #{component_number} is empty")
      end
      unless uppercase_byte?(current_byte)
        invalid("component #{component_number} must start with an uppercase letter")
      end

      start = @index
      @index += 1
      @index += 1 while identifier_byte?(current_byte)
      @components << @value.byteslice(start, @index - start)
    end

    def parse_separator
      unless current_byte == 58 && @value.getbyte(@index + 1) == 58
        invalid("expected `::` after component #{@components.length}")
      end
      @index += 2
    end

    def end_of_input?
      @index >= @value.bytesize
    end

    def current_byte
      @value.getbyte(@index)
    end

    def uppercase_byte?(byte)
      byte && byte.between?(65, 90)
    end

    def identifier_byte?(byte)
      byte && (uppercase_byte?(byte) || byte.between?(97, 122) || byte.between?(48, 57) || byte == 95)
    end

    def invalid(message)
      raise ::Arpaka::Error, "invalid class_name: #{message}"
    end
  end
end
