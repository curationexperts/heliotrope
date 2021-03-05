# frozen_string_literal: true

class ResourcePolicy < ApplicationPolicy
  include PolicyHelpers

  def index?
    true
  end

  def show?
    can? :read
  end

  def new?
    create?
  end

  def create?
    can? :create
  end

  def edit?
    update?
  end

  def update?
    can? :update
  end

  def destroy?
    can? :delete
  end
end
