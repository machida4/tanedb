# frozen_string_literal: true

module Tanedb
  class PageCache
    class ClockPolicy
      def initialize(capacity)
        @frames = Array.new(capacity) { { page_id: nil, ref: false } }
        @hand   = 0
      end

      def access(page_id)
        i = index_of(page_id)
        @frames[i][:ref] = true if i
      end

      # 空きがあればnil、なければevict対象のpage_idを返す
      def victim
        return nil if @frames.any? { |f| f[:page_id].nil? }

        loop do
          f = @frames[@hand]
          if f[:ref]
            f[:ref] = false
            advance
          else
            victim_id = f[:page_id]
            advance
            return victim_id
          end
        end
      end

      def load(page_id)
        i = index_of(nil) || @hand
        @frames[i] = { page_id: page_id, ref: true }
      end

      def evict(page_id)
        i = index_of(page_id)
        @frames[i] = { page_id: nil, ref: false } if i
      end

      private

      def advance
        @hand = (@hand + 1) % @frames.size
      end

      def index_of(page_id)
        @frames.index { |f| f[:page_id] == page_id }
      end
    end
  end
end
