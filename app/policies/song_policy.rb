class SongPolicy < ApplicationPolicy
  def index?
    member_of?(record.group)
  end

  def create?
    host_of?(record.group)
  end

  def destroy?
    host_of?(record.group)
  end
end
