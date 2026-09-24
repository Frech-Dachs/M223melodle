class GroupPolicy < ApplicationPolicy
  def create?
    user.present?
  end

  def show?
    member_of?(record)
  end

  def leaderboard?
    show?
  end

  def manage_members?
    host_of?(record)
  end

  class Scope < Scope
    def resolve
      scope.joins(:memberships).where(memberships: { user_id: user.id })
    end
  end
end
