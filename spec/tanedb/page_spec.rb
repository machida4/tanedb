# frozen_string_literal: true

RSpec.describe Tanedb::Page do
  subject(:page) { described_class.new }

  describe "#insert / #fetch" do
    it "挿入したレコードをslot_idで取得できる" do
      slot_id = page.insert("hello")
      expect(page.fetch(slot_id)).to eq("hello")
    end

    it "複数レコードをそれぞれ独立して取得できる" do
      id0 = page.insert("foo")
      id1 = page.insert("bar")
      expect(page.fetch(id0)).to eq("foo")
      expect(page.fetch(id1)).to eq("bar")
    end

    it "slot_idは0から連番で振られる" do
      expect(page.insert("a")).to eq(0)
      expect(page.insert("b")).to eq(1)
      expect(page.insert("c")).to eq(2)
    end

    it "存在しないslot_idはArgumentError" do
      expect { page.fetch(0) }.to raise_error(ArgumentError)
    end
  end

  describe "#each_record" do
    it "挿入順にレコードを列挙する" do
      page.insert("x")
      page.insert("y")
      expect(page.each_record.to_a).to eq(["x", "y"])
    end
  end

  describe "#full?" do
    it "空のページはfullでない" do
      expect(page).not_to be_full
    end

    it "容量を超えるデータを詰めるとfullになる" do
      chunk = "a" * 100
      page.insert(chunk) until page.full?
      expect(page).to be_full
    end
  end

  describe "#serialize / .from_bytes" do
    it "PAGE_SIZEバイトのStringを返す" do
      expect(page.serialize.bytesize).to eq(Tanedb::DiskManager::PAGE_SIZE)
    end

    it "シリアライズ→デシリアライズでレコードが復元される" do
      page.insert("hello")
      page.insert("world")

      restored = described_class.from_bytes(page.serialize)
      expect(restored.fetch(0)).to eq("hello")
      expect(restored.fetch(1)).to eq("world")
    end
  end
end
