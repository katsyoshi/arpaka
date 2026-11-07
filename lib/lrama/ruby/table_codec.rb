# frozen_string_literal: true

require "zlib"

module Lrama
  module Ruby
    module TableCodec
      module_function

      def encode(values)
        bytes = []
        values.each do |value|
          raise TypeError, "table values must be integers" unless value.is_a?(Integer)

          unsigned = value.negative? ? (-value * 2) - 1 : value * 2
          while unsigned >= 0x80
            bytes << ((unsigned & 0x7f) | 0x80)
            unsigned >>= 7
          end
          bytes << unsigned
        end
        bytes.pack("C*").force_encoding(Encoding::BINARY)
      end

      def compress(values)
        [Zlib::Deflate.deflate(encode(values))].pack("m0")
      end

      def decode(encoded)
        bytes = Zlib::Inflate.inflate(encoded.unpack1("m0")).bytes
        values = []
        value = 0
        shift = 0
        bytes.each do |byte|
          value |= (byte & 0x7f) << shift
          if byte < 0x80
            values << (value.even? ? value / 2 : -(value / 2) - 1)
            value = 0
            shift = 0
          else
            shift += 7
          end
        end
        raise ArgumentError, "invalid parser table encoding" unless shift.zero?

        values.freeze
      end
    end
  end
end
