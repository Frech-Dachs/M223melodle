# frozen_string_literal: true

class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def index?
    false
  end

  def show?
    false
  end

  def create?
    false
  end

  def new?
    create?
  end

  def update?
    false
  end

  def edit?
    update?
  end

  def destroy?
    false
  end

  private

  # Role is per group: it comes from the user's Membership in that group.
  def membership_in(group)
    return nil unless user && group
    user.memberships.find_by(group_id: group.id)
  end

  def member_of?(group)
    membership_in(group).present?
  end

  def host_of?(group)
    membership_in(group)&.host? || false
  end

  public

  class Scope
    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      raise NoMethodError, "You must define #resolve in #{self.class}"
    end

    private

    attr_reader :user, :scope
  end
end
