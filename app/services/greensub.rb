# frozen_string_literal: true

require_dependency 'greensub/component'
require_dependency 'greensub/components_product'
require_dependency 'greensub/full_license'
require_dependency 'greensub/individual'
require_dependency 'greensub/institution'
require_dependency 'greensub/license'
require_dependency 'greensub/license_credential'
require_dependency 'greensub/licensee'
require_dependency 'greensub/product'
require_dependency 'greensub/trial_license'

module Greensub
  class << self
    def actor_products(actor)
      products = actor.individual&.products || []
      actor.institutions.each do |institution|
        products += institution.products
      end
      products.uniq
    end

    def product_include?(product:, entity:)
      return false unless product.present? && entity.present?
      noids = product.components.map(&:noid)
      noids.include?(entity.noid)
    end
  end
end
