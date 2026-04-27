# frozen_string_literal: true

RSpec.describe Tanedb::Schema do
  subject(:schema) do
    described_class.new(id: :integer, score: :float, name: :string)
  end

  describe "#serialize / #deserialize" do
    let(:row) { { id: 42, score: 3.14, name: "alice" } }

    it "シリアライズ→デシリアライズで元のrowに戻る" do
      expect(schema.deserialize(schema.serialize(row))).to eq(row)
    end

    it "integerは8バイト (big-endian)" do
      bytes = schema.serialize(row)
      expect(bytes.byteslice(0, 8).unpack1("q>")).to eq(42)
    end

    it "floatは8バイト (IEEE 754 double)" do
      bytes = schema.serialize(row)
      expect(bytes.byteslice(8, 8).unpack1("G")).to eq(3.14)
    end

    it "stringは2バイト長プレフィックス + UTF-8" do
      bytes  = schema.serialize(row)
      offset = 16  # integer(8) + float(8)
      len    = bytes.byteslice(offset, 2).unpack1("n")
      expect(bytes.byteslice(offset + 2, len)).to eq("alice")
    end

    it "空のstringも扱える" do
      row2 = { id: 0, score: 0.0, name: "" }
      expect(schema.deserialize(schema.serialize(row2))).to eq(row2)
    end

    it "マルチバイト文字列も扱える" do
      row2 = { id: 1, score: 0.0, name: "田中" }
      expect(schema.deserialize(schema.serialize(row2))).to eq(row2)
    end

    it "負のintegerも扱える" do
      row2 = { id: -1, score: 0.0, name: "" }
      expect(schema.deserialize(schema.serialize(row2))[:id]).to eq(-1)
    end
  end

  describe "#column_names" do
    it "定義順でカラム名を返す" do
      expect(schema.column_names).to eq(%i[id score name])
    end
  end

  describe "未知の型" do
    it "ArgumentErrorを発生させる" do
      expect { described_class.new(x: :blob) }.to raise_error(ArgumentError)
    end
  end
end
