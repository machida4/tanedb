# frozen_string_literal: true

require "tmpdir"

RSpec.describe Tanedb::TableHeap do
  let(:path) { File.join(Dir.tmpdir, "tanedb_heap_#{Process.pid}.db") }
  subject(:heap) { described_class.open(path) }

  after do
    heap.close
    File.delete(path) if File.exist?(path)
  end

  describe "#insert / #each_record" do
    it "挿入したレコードを順番に取得できる" do
      heap.insert("alice")
      heap.insert("bob")
      expect(heap.each_record.to_a).to eq(["alice", "bob"])
    end
  end

  describe "複数ページへのあふれ" do
    it "ページが満杯になったら次のページに書き込む" do
      records = 60.times.map { |i| "record_#{i.to_s.rjust(3, "0")}" }
      records.each { |r| heap.insert(r) }
      expect(heap.each_record.to_a).to eq(records)
    end
  end

  describe "永続化" do
    it "closeして開き直してもレコードが残る" do
      heap.insert("alice")
      heap.insert("bob")
      heap.close

      heap2 = described_class.open(path)
      expect(heap2.each_record.to_a).to eq(["alice", "bob"])
      heap2.close
    end
  end
end
