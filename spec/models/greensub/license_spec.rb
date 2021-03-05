# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Greensub::License, type: :model do
  context 'Subclass Not Found' do
    subject { described_class.new(id: id, type: type) }

    let(:id) { 1 }
    let(:type) { 'type' }

    it { expect { subject }.to raise_exception(ActiveRecord::SubclassNotFound) }
  end

  describe 'Full License' do
    subject { license }

    let(:license) { create(:full_license) }

    it { expect { subject }.not_to raise_exception }
    it { expect(subject).to be_an_instance_of(Greensub::FullLicense) }
    it { expect(subject.label).to eq 'Full' }
    it { expect(subject.entitlements).to contain_exactly(:download, :reader) }
    it { expect(subject.allows?(:download)).to be true }
    it { expect(subject.allows?(:reader)).to be true }
  end

  describe 'Trial License' do
    subject { license }

    let(:license) { create(:trial_license) }

    it { expect { subject }.not_to raise_exception }
    it { expect(subject).to be_an_instance_of(Greensub::TrialLicense) }
    it { expect(subject.label).to eq 'Trial' }
    it { expect(subject.entitlements).to contain_exactly(:reader) }
    it { expect(subject.allows?(:download)).to be false }
    it { expect(subject.allows?(:reader)).to be true }
  end

  describe 'License' do
    subject { license }

    let(:license) { create(:license) }

    it { expect { subject }.not_to raise_exception }
    it { expect(subject).to be_an_instance_of(Greensub::License) }
    it { expect(subject.label).to eq 'Null' }
    it { expect(subject.entitlements).to be_empty }
    it { expect(subject.allows?(:download)).to be false }
    it { expect(subject.allows?(:reader)).to be false }

    it { expect(subject.allows?(:action)).to be false }
    it { expect(subject.update?).to be true }
    it { expect(subject.destroy?).to be true }
    it { expect(subject.credential_id).to eq Greensub::License.first.id }
    it { expect(subject.credential_type).to be :License }
    it { expect(subject.to_credential).to be_an_instance_of(Greensub::LicenseCredential) }
    it { expect(subject.licensee?).to be false }
    it { expect(subject.licensee).to be nil }
    it { expect(subject.individual?).to be false }
    it { expect(subject.individual).to be nil }
    it { expect(subject.institution?).to be false }
    it { expect(subject.institution).to be nil }
    it { expect(subject.product?).to be false }
    it { expect(subject.product).to be nil }
    it { expect(subject.destroy).to be license }

    it 'updates' do
      id = license.id
      expect(license).to be_an_instance_of(Greensub::License)
      expect(license.type).to eq "Greensub::License"
      license.type = "Greensub::TrialLicense"
      license.save
      license = Greensub::License.find(id)
      expect(license).to be_an_instance_of(Greensub::TrialLicense)
      expect(license.type).to eq "Greensub::TrialLicense"
      license.type = "Greensub::FullLicense"
      license.save
      license = Greensub::License.find(id)
      expect(license).to be_an_instance_of(Greensub::FullLicense)
      expect(license.type).to eq "Greensub::FullLicense"
    end
  end

  describe 'Individual License Grant' do
    subject { license }

    let(:individual) { create(:individual) }
    let(:license) { create(:full_license) }
    let(:product) { create(:product) }

    before do
      clear_grants_table
      Authority.grant!(individual, license, product)
    end

    it { expect(subject.allows?(:action)).to be false }
    it { expect(subject.update?).to be true }
    it { expect(subject.destroy?).to be false }
    it { expect(subject.credential_id).to eq license.id }
    it { expect(subject.credential_type).to be :License }
    it { expect(subject.to_credential).to be_an_instance_of(Greensub::LicenseCredential) }
    it { expect(subject.licensee?).to be true }
    it { expect(subject.licensee).to eq individual }
    it { expect(subject.individual?).to be true }
    it { expect(subject.individual).to eq individual }
    it { expect(subject.institution?).to be false }
    it { expect(subject.institution).to be nil }
    it { expect(subject.product?).to be true }
    it { expect(subject.product).to eq product }

    it 'destroy fails' do
      expect(subject.destroy).to be false
      expect(subject.errors.count).to eq 1
      expect(subject.errors.first[0]).to eq :base
      expect(subject.errors.first[1]).to eq "license has associated grant!"
    end
  end

  describe 'Institution License Grant' do
    subject { license }

    let(:institution) { create(:institution) }
    let(:license) { create(:full_license) }
    let(:product) { create(:product) }

    before do
      clear_grants_table
      Authority.grant!(institution, license, product)
    end

    it { expect(subject.allows?(:action)).to be false }
    it { expect(subject.update?).to be true }
    it { expect(subject.destroy?).to be false }
    it { expect(subject.credential_id).to eq license.id }
    it { expect(subject.credential_type).to be :License }
    it { expect(subject.to_credential).to be_an_instance_of(Greensub::LicenseCredential) }
    it { expect(subject.licensee?).to be true }
    it { expect(subject.licensee).to eq institution }
    it { expect(subject.individual?).to be false }
    it { expect(subject.individual).to be nil }
    it { expect(subject.institution?).to be true }
    it { expect(subject.institution).to eq institution }
    it { expect(subject.product?).to be true }
    it { expect(subject.product).to eq product }

    it 'destroy fails' do
      expect(subject.destroy).to be false
      expect(subject.errors.count).to eq 1
      expect(subject.errors.first[0]).to eq :base
      expect(subject.errors.first[1]).to eq "license has associated grant!"
    end
  end
end
