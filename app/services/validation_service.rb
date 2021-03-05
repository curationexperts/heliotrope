# frozen_string_literal: true

require 'ostruct'

class ValidationService
  # Class Methods

  # Syntax Validation a.k.a. Regular Expression Match? and such

  def self.valid_email?(email)
    /^[^@]+@[^@]+\.+[^@|\.]+$/.match?(email&.to_s)
  end

  def self.valid_id?(id)
    !!id&.to_i&.positive? # rubocop:disable Style/DoubleNegation
  end

  def self.valid_noid?(noid)
    /^[[:alnum:]]{9}$/.match?(noid)
  end

  def self.valid_uri?(uri)
    # URI = scheme:[//authority]path[?query][#fragment]
    # where authority = [userinfo@]host[:port]
    _parsed_uri = URI(uri)
    true
  rescue URI::InvalidURIError
    false
  end

  def self.valid_action?(action)
    case action
    when :create; true
    when :read; true
    when :update; true
    when :delete; true
    else false
    end
  end

  # Object Validation

  def self.valid_entity?(id)
    valid_noid?(id) && Sighrax.from_noid(id).valid?
  end

  def self.valid_component?(id)
    valid_id?(id) && Greensub::Component.find(id).present?
  end

  def self.valid_individual?(id)
    valid_id?(id) && Greensub::Individual.find(id).present?
  end

  def self.valid_institution?(id)
    valid_id?(id) && Greensub::Institution.find(id).present?
  end

  def self.valid_license_type?(license_type)
    # w%[Greensub::FullLicense Greensub::TrialLicense].include?(type)
    Greensub::License.new(type: license_type)
    true
  rescue ActiveRecord::SubclassNotFound
    false
  end

  def self.valid_license?(id)
    valid_id?(id) && Greensub::License.find(id).present?
  end

  def self.valid_product?(id)
    valid_id?(id) && Greensub::Product.find(id).present?
  end

  def self.valid_user?(id)
    valid_id?(id) && User.find(id).present?
  end

  # Agent Validation

  def self.valid_agent_type?(type)
    %i[any Guest Individual Institution User].include?(type&.to_s&.to_sym)
  end

  def self.valid_agent?(agent_type, agent_id) # rubocop:disable  Metrics/CyclomaticComplexity
    any_id = agent_id&.to_s&.to_sym == :any
    case agent_type&.to_s&.to_sym
    when :any
      any_id
    when :Guest
      any_id || valid_email?(agent_id)
    when :Individual
      any_id || valid_individual?(agent_id)
    when :Institution
      any_id || valid_institution?(agent_id)
    when :User
      any_id || valid_user?(agent_id)
    else
      false
    end
  end

  # Credential Validation

  def self.valid_permission?(permission)
    %i[read].include?(permission&.to_s&.to_sym)
  end

  def self.valid_credential_type?(type)
    %i[License permission].include?(type&.to_s&.to_sym)
  end

  def self.valid_credential?(credential_type, credential_id)
    any_id = credential_id&.to_s&.to_sym == :any
    case credential_type&.to_s&.to_sym
    # when :any
    #   any_id
    when :License
      # any_id || valid_license?(credential_id)
      valid_license?(credential_id)
    when :permission
      any_id || valid_permission?(credential_id)
    else
      false
    end
  end

  # Resource Validation

  def self.valid_resource_type?(type)
    %i[any Component Product].include?(type&.to_s&.to_sym)
  end

  def self.valid_resource?(resource_type, resource_id) # rubocop:disable  Metrics/CyclomaticComplexity
    any_id = resource_id&.to_s&.to_sym == :any
    case resource_type&.to_s&.to_sym
    when :any
      any_id
    when :Component
      any_id || valid_component?(resource_id)
    when :Product
      any_id || valid_product?(resource_id)
    else
      false
    end
  end

  # Actor Validation

  def self.valid_actor?(actor)
    return false if actor.blank?
    return true if actor.is_a?(Anonymous)
    return true if actor.is_a?(User)
    return true if actor.is_a?(Guest)
    false
  end
end
