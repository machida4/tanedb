# frozen_string_literal: true

module Tanedb
  class DiskManager
    PAGE_SIZE = 4096

    def initialize(path)
      if File.exist?(path)
        @file = File.open(path, "r+b")
      else
        @file = File.open(path, "w+b")
      end
    end

    def allocate_page
      page_id = page_count
      @file.seek(page_id * PAGE_SIZE)
      @file.write("\x00" * PAGE_SIZE)
      page_id
    end

    def write_page(page_id, data)
      raise ArgumentError, "data must be #{PAGE_SIZE} bytes, got #{data.bytesize}" unless data.bytesize == PAGE_SIZE
      raise ArgumentError, "page_id #{page_id} does not exist" if page_id >= page_count

      @file.seek(page_id * PAGE_SIZE)
      @file.write(data)
    end

    def read_page(page_id)
      raise ArgumentError, "page_id #{page_id} does not exist" if page_id >= page_count

      @file.seek(page_id * PAGE_SIZE)
      @file.read(PAGE_SIZE)
    end

    def flush
      @file.flush
      @file.fsync
    end

    def close
      @file.close
    end

    def page_count
      @file.size / PAGE_SIZE
    end
  end
end
