class GroupsController < ApplicationController
  before_action :require_login

  def new
    @group = Group.new
    authorize @group
  end

  def create
    authorize Group.new
    @group = Group.create_with_host!(group_params, current_user)
    redirect_to @group, notice: "Gruppe erstellt. Teile den Einladungscode mit deinen Freunden."
  rescue ActiveRecord::RecordInvalid => e
    @group = e.record
    render :new, status: :unprocessable_entity
  end

  def show
    @group = policy_scope(Group).find(params[:id]) # groups of other users do not exist for you: 404
    authorize @group
    @group.rounds.active.each(&:expire_if_needed!)
    @active_round = @group.rounds.active.first
    @memberships = @group.memberships.includes(:user).order(:created_at)
  end

  private

  def group_params
    params.expect(group: [ :name, :member_limit ])
  end
end
