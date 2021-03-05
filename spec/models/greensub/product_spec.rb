# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Greensub::Product, type: :model do
  context 'instance' do
    subject { described_class.new(id: id, identifier: identifier, name: name, purchase: purchase) }

    let(:id) { 1 }
    let(:identifier) { double('identifier') }
    let(:name) { double('name') }
    let(:purchase) { double('purchase') }

    it { expect(subject.resource_type).to eq :Product }
    it { expect(subject.resource_id).to eq id }
  end

  context 'before destroy' do
    let(:product) { create(:product) }
    let(:component) { create(:component) }

    it 'component present' do
      product.components << component
      expect(product.destroy).to be false
      expect(product.errors.count).to eq 1
      expect(product.errors.first[0]).to eq :base
      expect(product.errors.first[1]).to eq "product has associated component!"
    end

    it 'grants present' do
      individual = create(:individual)
      license = create(:full_license)
      Authority.grant!(individual, license, product)
      expect(product.destroy).to be false
      expect(product.errors.count).to eq 1
      expect(product.errors.first[0]).to eq :base
      expect(product.errors.first[1]).to eq "product has associated grant!"
    end
  end

  context "with components" do
    context "adding components" do
      let(:component) { create(:component) }
      let(:product) { create(:product) }

      it "runs the ReindexJob" do
        expect(product.components).to be_empty
        allow(ReindexJob).to receive(:perform_later).with(component.noid)
        product.components << component
        expect(ReindexJob).to have_received(:perform_later).with(component.noid)
        expect(product.components.count).to eq 1
      end
    end

    context "deleting compontents" do
      let(:component) { create(:component) }
      let(:product) { create(:product) }

      before do
        product.components << component
      end

      it "runs the ReindexJob" do
        expect(product.components.count).to eq 1
        allow(ReindexJob).to receive(:perform_later).with(component.noid)
        product.components.delete(component)
        expect(ReindexJob).to have_received(:perform_later).with(component.noid)
        expect(product.components).to be_empty
      end
    end
  end

  context 'methods' do
    subject { product }

    let(:product) { create(:product) }

    before { clear_grants_table }

    it do
      is_expected.to be_valid
      expect(subject.update?).to be true
      expect(subject.destroy?).to be true
      expect(subject.grants?).to be false
    end

    it 'components and not_components' do
      n = 3
      components = []
      n.times { components << create(:component) }

      expect(subject.update?).to be true
      expect(subject.destroy?).to be true

      components.each_with_index do |component, index|
        expect(subject.components.count).to eq(index)
        expect(subject.not_components.count).to eq(n - index)
        subject.components << component
        subject.save!
        expect(subject.update?).to be true
        expect(subject.destroy?).to be false
      end

      components.each_with_index do |component, index|
        expect(subject.update?).to be true
        expect(subject.destroy?).to be false
        expect(subject.components.count).to eq(n - index)
        expect(subject.not_components.count).to eq(index)
        subject.components.delete(component)
        subject.save!
      end

      expect(subject.update?).to be true
      expect(subject.destroy?).to be true
    end

    it '#grants?' do
      individual = create(:individual)
      individual_license = create(:full_license)
      institution = create(:institution)
      institution_license = create(:full_license)

      expect(subject.licensees?).to be false
      expect(subject.licensees).to be_empty
      expect(subject.individuals?).to be false
      expect(subject.individuals).to be_empty
      expect(subject.institutions?).to be false
      expect(subject.institutions).to be_empty
      expect(subject.licenses?).to be false
      expect(subject.licenses).to be_empty

      expect(subject.update?).to be true
      expect(subject.destroy?).to be true
      expect(subject.grants?).to be false

      Authority.grant!(individual, individual_license, subject)
      expect(subject.licensees?).to be true
      expect(subject.licensees).to contain_exactly(individual)
      expect(subject.individuals?).to be true
      expect(subject.individuals).to contain_exactly(individual)

      expect(subject.update?).to be true
      expect(subject.destroy?).to be false
      expect(subject.grants?).to be true

      Authority.grant!(institution, institution_license, subject)
      expect(subject.licensees?).to be true
      expect(subject.licensees).to contain_exactly(individual, institution)
      expect(subject.institutions?).to be true
      expect(subject.institutions).to contain_exactly(institution)

      expect(subject.update?).to be true
      expect(subject.destroy?).to be false
      expect(subject.grants?).to be true

      Authority.revoke!(individual, individual_license, subject)
      expect(subject.licensees?).to be true
      expect(subject.licensees).to contain_exactly(institution)
      expect(subject.individuals?).to be false
      expect(subject.individuals).to be_empty

      expect(subject.update?).to be true
      expect(subject.destroy?).to be false
      expect(subject.grants?).to be true

      Authority.revoke!(institution, institution_license, subject)
      expect(subject.licensees?).to be false
      expect(subject.licensees).to be_empty
      expect(subject.individuals?).to be false
      expect(subject.individuals).to be_empty
      expect(subject.institutions?).to be false
      expect(subject.institutions).to be_empty
      expect(subject.licenses?).to be false
      expect(subject.licenses).to be_empty

      expect(subject.update?).to be true
      expect(subject.destroy?).to be true
      expect(subject.grants?).to be false
    end
  end
end
