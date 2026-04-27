# frozen_string_literal: true

module Tanedb
  class TableHeap
    def self.open(path, capacity: 64)
      cache = PageCache.new(DiskManager.new(path), capacity: capacity)
      new(cache)
    end

    def initialize(cache)
      @cache = cache
    end

    def insert(record)
      page_id = find_page_with_space
      page    = @cache.fetch_page(page_id)
      slot_id = page.insert(record)
      @cache.mark_dirty(page_id)
      [page_id, slot_id]
    end

    def each_record
      return enum_for(:each_record) unless block_given?

      @cache.page_count.times do |page_id|
        @cache.fetch_page(page_id).each_record { |r| yield r }
      end
    end

    def close
      @cache.close
    end

    private

    def find_page_with_space
      @cache.page_count.times do |page_id|
        return page_id unless @cache.fetch_page(page_id).full?
      end
      page_id, _page = @cache.new_page
      page_id
    end
  end
end
