# frozen_string_literal: true

module Greensub
  class License < ApplicationRecord
    include Filterable

    scope :type_like, ->(like) { where("type like ?", "%#{like}%") }

    before_destroy do
      if grants?
        errors.add(:base, "license has associated grant!")
        throw(:abort)
      end
    end

    def entitlements
      []
    end

    def allows?(action)
      entitlements.include?(action)
    end

    def update?
      true
    end

    def destroy?
      grants.blank?
    end

    def credential_type
      :License
    end

    def credential_id
      id
    end

    def to_credential
      LicenseCredential.new(self.id)
    end

    def label
      return @label if @label.present?
      @label = 'Null' if self.instance_of?(Greensub::License)
      @label ||= /^Greensub::(.+)(License$)/.match(self.class.to_s)[1]
    end

    def licensee?
      licensee.present?
    end

    def licensee
      @licensee ||= individual || institution
    end

    def individual?
      individual.present?
    end

    def individual
      return nil if grants.blank?
      @individual ||= case grants.first.agent_type
                      when 'Individual'
                        Individual.find(grants.first.agent_id)
                      end
    end

    def institution?
      institution.present?
    end

    def institution
      return nil if grants.blank?
      @institution ||= case grants.first.agent_type
                       when 'Institution'
                         Institution.find(grants.first.agent_id)
                       end
    end

    def product?
      product.present?
    end

    def product
      return nil if grants.blank?
      @product ||= Product.find(grants.first.resource_id)
    end

    private

      def grants?
        grants.present?
      end

      def grants
        @grants ||= Checkpoint::DB::Grant.where(credential_type: 'License', credential_id: credential_id.to_i)
      end
  end
end
