# frozen_string_literal: true

class LicenseGrant < Checkpoint::DB::Grant
  def save!
    save
  end
end

FactoryBot.define do
  factory :license_grant, aliases: [:individual_license_grant], class: LicenseGrant do
    agent_type { "Individual" }
    sequence(:agent_id, &:to_s)
    agent_token { "#{agent_type}:#{agent_id}" }
    credential_type { "License" }
    sequence(:credential_id, &:to_s)
    credential_token { "#{credential_type}:#{credential_id}" }
    resource_type { "Product" }
    sequence(:resource_id, &:to_s)
    resource_token { "#{resource_type}:#{resource_id}" }
    zone_id { "(all)" }

    factory :institution_license_grant do
      agent_type { "Institution" }
    end
  end
end
