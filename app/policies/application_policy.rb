# frozen_string_literal: true

class ApplicationPolicy
  def initialize(actor, target)
    @actor = actor
    @target = target
  end

  def authorize!(action, message = nil)
    raise(NotAuthorizedError, message) unless send(action)
  end

  protected

    def actor_platform_admin?
      @actor_platform_admin ||= Sighrax.platform_admin?(actor)
    end

    def action_permitted?(action)
      Checkpoint::Query::ActionPermitted.new(actor, action, target, authority: authority).true? && Incognito.allow_action_permitted?(actor)
    rescue StandardError => e
      Rails.logger.error "ApplicationPolicy::action_permitted?(#{action}) #{e}"
      false
    end

    def authority
      Services.checkpoint
    end

    attr_reader :actor, :target

    def debug_log(msg)
      Rails.logger.debug "[POLICY] #{self.class} -- #{msg}"
    end
end
