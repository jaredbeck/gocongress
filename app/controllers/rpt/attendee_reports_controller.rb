class Rpt::AttendeeReportsController < Rpt::AbstractReportController

def show
  @attendees = Attendee.yr(@year).with_planlessness(planlessness)
  respond_to do |format|
    format.html do
      @attendee_count = @attendees.count
      @user_count = User.yr(@year).count
      @planless_attendee_count = Attendee.yr(@year).planless.count
      @planful_attendee_count = Attendee.yr(@year).count - @planless_attendee_count
      render :show
    end
    format.csv do
      @csv_header_line = csv_header_line
      render_csv("usgc_attendees_#{Time.now.strftime("%Y-%m-%d")}")
    end
  end
end

private

# The order of `csv_header_line` must match
# `attendee_to_array` in `reports_helper.rb`
def csv_header_line
  cols = ['user_email'].concat Attendee.attribute_names_for_csv
  Plan.yr(@year).order(:name).each { |p| cols << "Plan: " + safe_for_csv(p.name) }
  claimable_discounts = Discount.yr(@year).where('is_automatic = ?', false).order(:name)
  claimable_discounts.each { |d| cols << "Discount: " + safe_for_csv(d.name) }
  Tournament.yr(@year).order(:name).each { |t| cols << "Tournament: " + safe_for_csv(t.name) }
  cols.join(',')
end

def planlessness
  p = params[:planlessness]
  %w[all planful planless].include?(p) ? p.to_sym : :all
end

end
