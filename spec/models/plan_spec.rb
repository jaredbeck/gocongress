require "spec_helper"

describe Plan do
  it_behaves_like "a yearly model"

  it "has a valid factory" do
    FactoryGirl.build(:plan).should be_valid
  end

  describe '#valid' do
    it 'requires a nonzero inventory' do
      FactoryGirl.build(:plan, inventory: 0).should_not be_valid
    end

    it 'requires a positive max qty' do
      p = FactoryGirl.build(:plan, :max_quantity => 1)
      p.should be_valid
      p.max_quantity = 0
      p.should_not be_valid
      p.max_quantity = -1
      p.should_not be_valid
    end
  end

  describe '#inventory_consumed' do
    it 'is zero for a new plan' do
      Plan.new.inventory_consumed.should == 0
    end

    it 'returns the quantity of associated attendee_plan records' do
      p = FactoryGirl.create :plan, max_quantity: 3
      a = FactoryGirl.create :attendee
      FactoryGirl.create :attendee_plan, attendee: a, plan: p, quantity: 3, year: p.year
      p.inventory_consumed.should == 3
    end
  end

  context "when two attendees have selected it" do
    let(:plan) { FactoryGirl.create :plan }
    before do
      plan.stub attendees: ["alice", "bob"]
    end

    describe "#valid?" do
      it "returns false when inventory is less than attendee count" do
        plan.inventory = 1
        plan.valid?.should be_false
      end

      it "returns true when inventory is equal to attendee count" do
        plan.inventory = 2
        plan.valid?.should be_true
      end

      it "returns true when inventory exceeds attendee count" do
        plan.inventory = 3
        plan.valid?.should be_true
      end
    end
  end
end
