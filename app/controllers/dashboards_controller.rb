class DashboardsController < ApplicationController
  before_action :require_login

  def show
    @memberships = current_user.memberships.includes(:group).order("groups.name").references(:group)
  end
end
