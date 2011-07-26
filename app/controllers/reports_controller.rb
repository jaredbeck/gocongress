require 'csv'

class ReportsController < ApplicationController

  # Access Control
  before_filter :authorize_read_report
  def authorize_read_report() authorize! :read, :report end

  def attendees
    @attendees = Attendee.all
    @attendee_count = Attendee.all.count
    @user_count = User.all.count

    # build csv header line
    # the order here must match attendee_to_array() in reports_helper.rb
    cols = []    
    if @attendee_count > 0 then
      cols << 'user_email'
      cols << Attendee.first.attribute_names_for_csv
      Plan.order(:name).each { |p| cols << "Plan: " + safe_for_csv(p.name) }
      claimable_discounts = Discount.where('is_automatic = ?', false).order(:name)
      claimable_discounts.each { |d| cols << "Discount: " + safe_for_csv(d.name) }
      Tournament.order(:name).each { |t| cols << "Tournament: " + safe_for_csv(t.name) }
    end
    @csv_header_line = cols.join(',')
    
    respond_to do |format|
      format.html do render 'attendees.html.haml' end
      format.csv do render_csv("usgc_attendees_#{Time.now.strftime("%Y-%m-%d")}") end
    end
  end

  def atn_badges_all
    @attendees = Attendee.where('lower(substr(family_name,1,1)) between ? and ?', params[:min], params[:max])
    @attendees.order('family_name, given_name')
    render :layout => "print"
  end

  def atn_reg_sheets
    @attendee_attr_names = %w[aga_id birth_date comment confirmed email gender phone special_request roomate_request].sort
    @attendees = Attendee.where('lower(substr(family_name,1,1)) between ? and ?', params[:min], params[:max])
    @attendees.order('user_id, family_name, given_name')
    @tmt_names = AttendeeTournament.tmt_names_by_attendee
    render :layout => "print"
  end

  def index
  end

  def invoices
    @user_count = User.all.count
    @invoice_total_across_all_users = 0
    User.all.each { |u| @invoice_total_across_all_users += u.get_invoice_total }
  end

  def emails
    @atnd_email_list = ""
    Attendee.all.each { |a|
      @atnd_email_list += "\"#{a.get_full_name}\" <#{a.email}>, "
      }
  end

  def events
    @events = Event.order('start asc')
    @events_by_date = @events.group_by {|event| event.start.to_date}
  end

  def outstanding_balances
    @users = User.joins(:primary_attendee).order :family_name, :given_name
    @users.keep_if { |u| u.balance != 0.0 }
  end

  def overdue_deposits
    @overdue_users = []
    User.all.each { |u|
      is_deposit_paid = u.get_num_attendee_deposits_paid == u.attendees.count
      is_past_deposit_due_date = u.get_initial_deposit_due_date < Time.now.to_date
      if (is_past_deposit_due_date && !is_deposit_paid) then
        @overdue_users << u
      end
    }
    respond_to do |format|
      format.html do render 'overdue_deposits.html.haml' end
      format.csv do render_csv("usgc_overdue_users_#{Time.now.strftime("%Y-%m-%d")}") end
    end
  end

  def revenue
    @player_count = Attendee.where('is_player = ?', true).count
    @player_reg_revenue_sum = @player_count * Attendee.registration_price(:player)
    @nonplayer_count = Attendee.where('is_player = ?', false).count
    @nonplayer_reg_revenue_sum = @nonplayer_count * Attendee.registration_price(:nonplayer)

    @plan_categories = PlanCategory.where('show_on_reg_form = ?', true).order(:name)
    @hidden_plan_categories = PlanCategory.where('show_on_reg_form = ?', false).order(:name)
  end

  def transactions
    @transactions = Transaction.all
    @sales = Transaction.where("trantype = ?", "S")
    @comps = Transaction.where("trantype = ?", "C")
    @refunds = Transaction.where("trantype = ?", "R")
    
    @sales_sum = @sales.sum(:amount)
    @comps_sum = @comps.sum(:amount)
    @refunds_sum = @refunds.sum(:amount)
    @total_sum = @sales_sum - @comps_sum - @refunds_sum

    respond_to do |format|
      format.html do render 'transactions.html.haml' end
      format.csv do render_csv("usgc_transactions_#{Time.now.strftime("%Y-%m-%d")}") end
    end
  end

  def tournaments
    # Lisa wants "the US Open at the bottom, since it will be by far the longest"
    @tournaments = Tournament.order("name <> 'US Open' desc, name asc")
  end

  def user_invoices
    @users = User.joins(:primary_attendee)
    @users.where('lower(substr(family_name,1,1)) between ? and ?', params[:min], params[:max])
    @users.order('family_name, given_name')
    render :layout => "print"
  end

protected

  def page_title
    human_action_name.singularize + ' ' + human_controller_name
  end

private

  def render_csv(filename = nil)
    filename ||= params[:action]
    filename += '.csv'
  
    if request.env['HTTP_USER_AGENT'] =~ /msie/i
      headers['Pragma'] = 'public'
      headers["Content-type"] = "text/plain" 
      headers['Cache-Control'] = 'no-cache, must-revalidate, post-check=0, pre-check=0'
      headers['Content-Disposition'] = "attachment; filename=\"#{filename}\"" 
      headers['Expires'] = "0" 
    else
      headers["Content-Type"] ||= 'text/csv'
      headers["Content-Disposition"] = "attachment; filename=\"#{filename}\"" 
    end
  
    render :layout => false
  end

  def safe_for_csv(str)
    str.tr(',"', '')
  end

end
