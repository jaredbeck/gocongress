require "spec_helper"

describe AttendeesCsvExporter do

  describe "#attendee_array" do
    let(:atnd) { build :attendee }
    let(:ary) { AttendeesCsvExporter.attendee_array(atnd) }

    it "returns an array" do
      ary.should be_instance_of(Array)
    end

    it "has the user email in the first element" do
      ary.first.should == atnd.user.email
    end

    it "does not encode entities" do
      str_with_entity = "8>)"
      atnd.special_request = str_with_entity
      ary.should include(str_with_entity)
    end

    it "should have the correct number of elements" do
      create :plan
      na = AttendeesCsvExporter::AttendeeAttributes.names.length
      np = Plan.yr(atnd.year).count
      ary.should have(na + np + 3).elements
    end

    it "should include the guardian's full name" do
      minor = create :minor
      guardian_name = minor.guardian.full_name
      AttendeesCsvExporter.attendee_array(minor).should include(guardian_name)
    end
  end

  describe '#header_array' do
    let(:header) { AttendeesCsvExporter.header_array(Date.current.year) }

    it "includes guardian" do
      header.should include('guardian')
    end

    it "does not include guardian_attendee_id" do
      header.should_not include('guardian_attendee_id')
    end
  end
end
