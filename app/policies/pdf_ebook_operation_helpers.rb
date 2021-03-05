# frozen_string_literal: true

class PdfEbookOperationHelpers < ApplicationPolicy
  include PolicyHelpers

  protected

    def accessible_online?
      target.published? && !target.tombstone?
    end

    def accessible_offline?
      target.allow_download? && accessible_online?
    end

    def unrestricted?
      target.open_access? || !target.restricted?
    end

    def licensed_for?(entitlement)
      authority
        .licenses_for(actor, target)
        .any? { |license| license.allows?(entitlement) }
    end
end
