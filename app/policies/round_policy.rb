class RoundPolicy < ApplicationPolicy
  def show?
    member_of?(record.group)
  end

  def create?
    host_of?(record.group)
  end

  def finish?
    host_of?(record.group)
  end

  def guess?
    member_of?(record.group)
  end
end
