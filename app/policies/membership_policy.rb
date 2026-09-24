class MembershipPolicy < ApplicationPolicy
  # The host removes other members, never themselves.
  def destroy?
    host_of?(record.group) && record.user_id != user.id
  end
end
