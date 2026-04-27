# frozen_string_literal: true

require "tmpdir"

RSpec.describe Tanedb::PageCache do
  let(:path)  { File.join(Dir.tmpdir, "tanedb_cache_#{Process.pid}.db") }
  let(:disk)  { Tanedb::DiskManager.new(path) }
  subject(:cache) { described_class.new(disk, capacity: 3) }

  after do
    cache.close
    File.delete(path) if File.exist?(path)
  end

  describe "#new_page" do
    it "新しいページとそのIDを返す" do
      page_id, page = cache.new_page
      expect(page_id).to eq(0)
      expect(page).to be_a(Tanedb::Page)
    end
  end

  describe "#fetch_page" do
    it "キャッシュ済みのページを同じオブジェクトで返す" do
      page_id, _ = cache.new_page
      expect(cache.fetch_page(page_id)).to be(cache.fetch_page(page_id))
    end

    it "evict後に再fetchするとディスクから復元される" do
      ids = 3.times.map do
        page_id, page = cache.new_page
        page.insert("data_#{page_id}")
        cache.mark_dirty(page_id)
        page_id
      end
      cache.new_page  # page 0 が evict → ディスクへ書き戻し

      restored = cache.fetch_page(ids.first)
      expect(restored.fetch(0)).to eq("data_0")
    end
  end

  describe "#flush_all" do
    it "dirtyなページをディスクに書き込む" do
      page_id, page = cache.new_page
      page.insert("persist")
      cache.mark_dirty(page_id)
      cache.flush_all

      restored = Tanedb::Page.from_bytes(disk.read_page(page_id))
      expect(restored.fetch(0)).to eq("persist")
    end
  end

  describe "eviction" do
    it "キャッシュが満杯のとき dirty なページを書き戻してから追い出す" do
      ids = 3.times.map do
        page_id, page = cache.new_page
        page.insert("data_#{page_id}")
        cache.mark_dirty(page_id)
        page_id
      end

      cache.new_page  # page 0 が evict される

      restored = Tanedb::Page.from_bytes(disk.read_page(ids.first))
      expect(restored.fetch(0)).to eq("data_0")
    end
  end
end
