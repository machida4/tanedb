# frozen_string_literal: true

module Tanedb
  class Page
    PAGE_SIZE   = DiskManager::PAGE_SIZE
    HEADER_SIZE = 4  # slot_count(2) + free_end(2)
    SLOT_SIZE   = 4  # offset(2) + length(2)

    def initialize
      @slots    = []  # [{offset:, length:}, ...]
      @data_buf = +""  # レコードデータ (末尾から積む、内部では先頭からの逆順)
    end

    def insert(record)
      raise "page is full" if full?

      bytes  = record.b
      @data_buf.prepend(bytes)
      offset = PAGE_SIZE - @data_buf.bytesize
      @slots << { offset: offset, length: bytes.bytesize }
      @slots.length - 1
    end

    def fetch(slot_id)
      slot = @slots[slot_id]
      raise ArgumentError, "slot_id #{slot_id} does not exist" unless slot

      buf_offset = slot[:offset] - (PAGE_SIZE - @data_buf.bytesize)
      @data_buf.byteslice(buf_offset, slot[:length]).force_encoding(Encoding::UTF_8)
    end

    def each_record
      return enum_for(:each_record) unless block_given?

      @slots.each_index { |i| yield fetch(i) }
    end

    def full?
      free_space < SLOT_SIZE + 1
    end

    def serialize
      buf = "\x00".b * PAGE_SIZE

      slot_count = @slots.length
      free_end   = @slots.empty? ? PAGE_SIZE : @slots.map { |s| s[:offset] }.min

      buf.setbyte(0, (slot_count >> 8) & 0xff)
      buf.setbyte(1,  slot_count       & 0xff)
      buf.setbyte(2, (free_end   >> 8) & 0xff)
      buf.setbyte(3,  free_end         & 0xff)

      @slots.each_with_index do |slot, i|
        base = HEADER_SIZE + i * SLOT_SIZE
        buf.setbyte(base,     (slot[:offset] >> 8) & 0xff)
        buf.setbyte(base + 1,  slot[:offset]       & 0xff)
        buf.setbyte(base + 2, (slot[:length] >> 8) & 0xff)
        buf.setbyte(base + 3,  slot[:length]       & 0xff)
      end

      buf[PAGE_SIZE - @data_buf.bytesize, @data_buf.bytesize] = @data_buf

      buf
    end

    def self.from_bytes(bytes)
      raise ArgumentError, "bytes must be #{PAGE_SIZE} bytes" unless bytes.bytesize == PAGE_SIZE

      page = new

      slot_count = (bytes.getbyte(0) << 8) | bytes.getbyte(1)
      free_end   = (bytes.getbyte(2) << 8) | bytes.getbyte(3)

      slots = slot_count.times.map do |i|
        base   = HEADER_SIZE + i * SLOT_SIZE
        offset = (bytes.getbyte(base)     << 8) | bytes.getbyte(base + 1)
        length = (bytes.getbyte(base + 2) << 8) | bytes.getbyte(base + 3)
        { offset: offset, length: length }
      end

      page.instance_variable_set(:@slots, slots)
      data_start = free_end
      page.instance_variable_set(:@data_buf, bytes[data_start..].b)

      page
    end

    private

    def free_space
      dir_end = HEADER_SIZE + @slots.length * SLOT_SIZE
      data_start = PAGE_SIZE - @data_buf.bytesize
      data_start - dir_end
    end
  end
end
