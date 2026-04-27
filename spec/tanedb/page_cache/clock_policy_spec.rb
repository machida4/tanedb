# frozen_string_literal: true

RSpec.describe Tanedb::PageCache::ClockPolicy do
  subject(:policy) { described_class.new(3) }

  describe "#victim" do
    it "空きフレームがある間はnilを返す" do
      expect(policy.victim).to be_nil
      policy.load(0)
      expect(policy.victim).to be_nil
    end

    context "全フレームが埋まった後" do
      before { policy.load(0); policy.load(1); policy.load(2) }

      it "ref=trueのページは一巡消費してから追い出す (最初のロードが最初のvictim)" do
        expect(policy.victim).to eq(0)
      end

      it "accessしたページはref=trueに戻り、次のvictimをスキップする" do
        policy.victim          # 0 が選ばれ手が1へ
        policy.evict(0)
        policy.load(3)         # frames: [{3,true},{1,false},{2,false}], hand=1

        policy.access(1)       # 1 の ref を true に戻す

        expect(policy.victim).to eq(2)   # 1 はスキップされ 2 が選ばれる
      end
    end
  end
end
