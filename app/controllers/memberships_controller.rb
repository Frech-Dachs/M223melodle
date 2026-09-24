class MembershipsController < ApplicationController
  before_action :require_login

  def destroy
    group = policy_scope(Group).find(params[:group_id])
    membership = group.memberships.find(params[:id])
    authorize membership

    group.remove_member!(membership)
    redirect_to group, notice: "#{membership.user.display_name} wurde entfernt."
  end
end
