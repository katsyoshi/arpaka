# frozen_string_literal: true

require_relative "lrama/ruby"
require_relative "lrama/ruby/languages/ruby"

# Public name for the Ruby language frontend. The implementation currently
# lives below Lrama::Ruby::Languages::Ruby while the backend is being split
# from the frontend.
Arpaka = Lrama::Ruby::Languages::Ruby unless defined?(Arpaka)
