# frozen_string_literal: true

module Tanedb
  class TableHeap
    def initialize(path)
      @disk = DiskManager.new(path)
    end

    def insert(record)
      page_id = find_page_with_space
      page = load_page(page_id)
      slot_id = page.insert(record)
      save_page(page_id, page)
      [page_id, slot_id]
    end

    def each_record
      return enum_for(:each_record) unless block_given?

      @disk.page_count.times do |page_id|
        load_page(page_id).each_record { |r| yield r }
      end
    end

    def close
      @disk.close
    end

    private

    def find_page_with_space
      @disk.page_count.times do |page_id|
        return page_id unless load_page(page_id).full?
      end
      allocate_new_page
    end

    def allocate_new_page
      page_id = @disk.allocate_page
      save_page(page_id, Page.new)
      page_id
    end

    def load_page(page_id)
      Page.from_bytes(@disk.read_page(page_id))
    end

    def save_page(page_id, page)
      @disk.write_page(page_id, page.serialize)
    end
  end
end
