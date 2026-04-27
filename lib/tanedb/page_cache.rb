# frozen_string_literal: true

require_relative "page_cache/clock_policy"

module Tanedb
  class PageCache
    def initialize(disk, capacity: 64, policy: nil)
      @disk     = disk
      @capacity = capacity
      @policy   = policy || ClockPolicy.new(capacity)
      @entries  = {}  # page_id => { page:, dirty: }
    end

    def fetch_page(page_id)
      if @entries.key?(page_id)
        @policy.access(page_id)
        return @entries[page_id][:page]
      end

      make_room
      page = Page.from_bytes(@disk.read_page(page_id))
      @entries[page_id] = { page: page, dirty: false }
      @policy.load(page_id)
      page
    end

    def new_page
      page_id = @disk.allocate_page
      make_room
      page = Page.new
      @entries[page_id] = { page: page, dirty: true }
      @policy.load(page_id)
      [page_id, page]
    end

    def mark_dirty(page_id)
      @entries[page_id][:dirty] = true if @entries.key?(page_id)
    end

    def flush_all
      @entries.each do |page_id, entry|
        next unless entry[:dirty]

        @disk.write_page(page_id, entry[:page].serialize)
        entry[:dirty] = false
      end
      @disk.flush
    end

    def page_count
      @disk.page_count
    end

    def close
      flush_all
      @disk.close
    end

    private

    def make_room
      return if @entries.size < @capacity

      victim_id = @policy.victim
      return unless victim_id

      entry = @entries.delete(victim_id)
      @disk.write_page(victim_id, entry[:page].serialize) if entry[:dirty]
      @policy.evict(victim_id)
    end
  end
end
