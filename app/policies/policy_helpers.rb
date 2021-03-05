# frozen_string_literal: true

module PolicyHelpers
  protected

    def can?(action, agent: actor, resource: target, publisher: target.publisher) # rubocop:disable  Metrics/CyclomaticComplexity
      # Checkpoint::Query::ActionPermitted.new(user, action, resource, authority: authority).true?
      # These methods should transform into authority questions
      return false unless ValidationService.valid_action?(action)

      return true if agent.platform_admin?

      return false unless agent.presses.include?(publisher.press)

      return true if agent.admin_presses.include?(publisher.press)

      case action
      when :create
        agent.editor_presses.include?(publisher.press)
      when :read
        agent.presses.include?(publisher.press)
      when :update
        agent.editor_presses.include?(publisher.press)
      when :delete
        agent.editor_presses.include?(publisher.press)
      else
        false
      end
    end

    def authority
      Services.checkpoint
    end
end
