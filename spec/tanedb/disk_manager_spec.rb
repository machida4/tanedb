# frozen_string_literal: true

require "tmpdir"

RSpec.describe Tanedb::DiskManager do
  let(:path) { File.join(Dir.tmpdir, "tanedb_test_#{Process.pid}.db") }
  subject(:dm) { described_class.new(path) }

  after do
    dm.close
    File.delete(path) if File.exist?(path)
  end

  describe "#allocate_page" do
    it "最初のページIDとして0を返す" do
      expect(dm.allocate_page).to eq(0)
    end

    it "連番でIDを返す" do
      ids = 3.times.map { dm.allocate_page }
      expect(ids).to eq([0, 1, 2])
    end
  end

  describe "#page_count" do
    it "アロケート前は0" do
      expect(dm.page_count).to eq(0)
    end

    it "アロケートするたびに増える" do
      3.times { dm.allocate_page }
      expect(dm.page_count).to eq(3)
    end
  end

  describe "#write_page / #read_page" do
    it "書いた内容をそのまま読み返せる" do
      page_id = dm.allocate_page
      data = "hello".b.ljust(Tanedb::DiskManager::PAGE_SIZE, "\x00")
      dm.write_page(page_id, data)
      expect(dm.read_page(page_id)).to eq(data)
    end

    it "PAGE_SIZEと異なるデータはArgumentError" do
      dm.allocate_page
      expect { dm.write_page(0, "short") }.to raise_error(ArgumentError)
    end

    it "存在しないpage_idへの書き込みはArgumentError" do
      expect { dm.write_page(0, "\x00" * Tanedb::DiskManager::PAGE_SIZE) }.to raise_error(ArgumentError)
    end

    it "存在しないpage_idからの読み込みはArgumentError" do
      expect { dm.read_page(0) }.to raise_error(ArgumentError)
    end
  end

  describe "永続化" do
    it "flush後にファイルを開き直しても内容が残る" do
      page_id = dm.allocate_page
      data = "persist".b.ljust(Tanedb::DiskManager::PAGE_SIZE, "\x00")
      dm.write_page(page_id, data)
      dm.flush
      dm.close

      dm2 = described_class.new(path)
      expect(dm2.read_page(page_id)).to eq(data)
      dm2.close
    end
  end
end
