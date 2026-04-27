# frozen_string_literal: true

module Tanedb
  class Schema
    TYPES = %i[integer float string].freeze

    def initialize(columns)
      @columns = columns.each_with_object({}) do |(name, type), h|
        raise ArgumentError, "unknown type: #{type}" unless TYPES.include?(type)

        h[name] = type
      end
    end

    def serialize(row)
      @columns.map do |name, type|
        value = row[name]
        case type
        when :integer then [value].pack("q>")
        when :float   then [value].pack("G")
        when :string
          bytes = value.to_s.b
          [bytes.bytesize].pack("n") + bytes
        end
      end.join.b
    end

    def deserialize(bytes)
      row    = {}
      offset = 0
      @columns.each do |name, type|
        case type
        when :integer
          row[name] = bytes.byteslice(offset, 8).unpack1("q>")
          offset += 8
        when :float
          row[name] = bytes.byteslice(offset, 8).unpack1("G")
          offset += 8
        when :string
          len      = bytes.byteslice(offset, 2).unpack1("n")
          offset  += 2
          row[name] = bytes.byteslice(offset, len).force_encoding(Encoding::UTF_8)
          offset  += len
        end
      end
      row
    end

    def column_names
      @columns.keys
    end

    def column_type(name)
      @columns[name]
    end
  end
end
