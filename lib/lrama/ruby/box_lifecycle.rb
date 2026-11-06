# frozen_string_literal: true

module Lrama
  module Ruby
    # Ruby 4.0.9's Ruby::Box loader cannot initialize a new Box after a
    # Ractor has run: Ruby::Box::Loader#require_relative loses its super
    # target while loading error_highlight.rb. Keep the boxes used by the
    # generators alive and reuse them instead of constructing them lazily.
    module BoxLifecycle
      @boxes = {}
      @mutex = Mutex.new

      class << self
        def prepare(*names)
          @mutex.synchronize do
            names.each { |name| box_for(name) }
          end
        end

        def with(name)
          @mutex.synchronize { yield box_for(name) }
        end

        def remove_constant(box, components)
          namespace = box
          components.each_with_index do |component, index|
            name = component.to_sym
            if index == components.length - 1
              namespace.__send__(:remove_const, name) if namespace.const_defined?(name, false)
            else
              return unless namespace.const_defined?(name, false)
              namespace = namespace.const_get(name, false)
            end
          end
        end

        private

        def box_for(name)
          @boxes[name] ||= ::Ruby::Box.new
        end
      end
    end
  end
end
