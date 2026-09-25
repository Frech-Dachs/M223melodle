class ActivitiesController < ApplicationController
  before_action :require_login

  def index
    @group = policy_scope(Group).find(params[:group_id])
    authorize @group, :show?
    @activities = @group.activities.includes(:actor).order(created_at: :desc, id: :desc).limit(100)
  end
end
