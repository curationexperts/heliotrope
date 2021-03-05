# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ValidationService do
  describe '#valid_email?' do
    it { expect(described_class.valid_email?(nil)).to be false }
    it { expect(described_class.valid_email?('')).to be false }
    it { expect(described_class.valid_email?('wolverine')).to be false }
    it { expect(described_class.valid_email?('wolverine@')).to be false }
    it { expect(described_class.valid_email?('wolverine@umich')).to be false }
    it { expect(described_class.valid_email?('wolverine@umich.')).to be false }
    it { expect(described_class.valid_email?('wolverine@umich.edu')).to be true }
  end

  describe '#valid_id?' do
    it { expect(described_class.valid_id?(nil)).to be false }
    it { expect(described_class.valid_id?('')).to be false }
    it { expect(described_class.valid_id?('id')).to be false }
    it { expect(described_class.valid_id?('-1')).to be false }
    it { expect(described_class.valid_id?('0')).to be false }
    it { expect(described_class.valid_id?('1')).to be true }
    it { expect(described_class.valid_id?(-1)).to be false }
    it { expect(described_class.valid_id?(0)).to be false }
    it { expect(described_class.valid_id?(1)).to be true }
  end

  describe '#valid_noid?' do
    let(:noid) { 'invalidnoid' }

    it { expect(described_class.valid_noid?(noid)).to be false }

    context 'valid' do
      let(:noid) { 'validnoid' }

      it { expect(described_class.valid_noid?(noid)).to be true }
    end
  end

  describe '#valid_uri?' do
    let(:uri) { '' }

    it { expect(described_class.valid_uri?(uri)).to be true }

    context 'invalid' do
      let(:uri) { 'valid uri' }

      it { expect(described_class.valid_uri?(uri)).to be false }
    end

    context 'valid' do
      let(:uri) { 'valid_uri' }

      it { expect(described_class.valid_uri?(uri)).to be true }
    end
  end

  describe '#valid_action?' do
    subject { described_class.valid_action?(action) }

    context 'unknown' do
      let (:action) { :unknown }

      it 'false' do is_expected.to be false end
    end

    %i[create read update delete].each do |action|
      context "#{action}" do
        let(:action) { action }

        it "true" do is_expected.to be true end
      end
    end
  end


  describe "#valid_entity?" do
    subject { described_class.valid_entity?(id) }

    let(:id) { double('id') }
    let(:valid_id) { false }
    let(:entity) { double('entity', valid?: valid) }
    let(:valid) { false }

    before do
      allow(described_class).to receive(:valid_noid?).with(id).and_return(valid_id)
      allow(Sighrax).to receive(:from_noid).with(id).and_return(entity)
    end

    it { is_expected.to be false }

    context 'valid id' do
      let(:valid_id) { true }

      it { is_expected.to be false }

      context 'found' do
        let(:valid) { true }

        it { is_expected.to be true }
      end
    end
  end

  [Greensub::Component, Greensub::Individual, Greensub::Institution, Greensub::License, Greensub::Product, User].each do |klass|
    relative_klass_match = /^Greensub::(.+$)/.match(klass.to_s)
    relative_klass = relative_klass_match[1].to_sym if relative_klass_match.present?
    relative_klass ||= klass
    method = "valid_#{relative_klass.to_s.downcase}?".to_sym

    describe "##{method}" do
      subject { described_class.send(method, id) }

      let(:id) { double('id') }
      let(:valid_id) { false }
      let(:object) { }

      before do
        allow(described_class).to receive(:valid_id?).with(id).and_return(valid_id)
        allow(klass).to receive(:find).with(id).and_return(object)
      end

      it { is_expected.to be false }

      context 'valid id' do
        let(:valid_id) { true }

        it { is_expected.to be false }

        context 'found' do
          let(:object) { double('object') }

          it { is_expected.to be true }
        end
      end
    end
  end

  describe '#valid_agent_type? and #valid_agent?' do
    subject { described_class.valid_agent?(agent_type, agent_id) }

    let(:agent_type) { 'agent_type' }
    let(:agent_id) { 'agent_id' }

    it { expect(described_class.valid_agent_type?(agent_type)).to be false }
    it { is_expected.to be false }

    context 'any' do
      let(:agent_type) { :any }

      it { expect(described_class.valid_agent_type?(agent_type)).to be true }
      it { is_expected.to be false }

      context 'valid' do
        let(:agent_id) { 'any' }

        it { is_expected.to be true }
      end
    end

    context 'Guest' do
      let(:agent_type) { :Guest }

      it { expect(described_class.valid_agent_type?(agent_type)).to be true }
      it { is_expected.to be false }

      context 'any' do
        let(:agent_id) { 'any' }

        it { expect(described_class.valid_email?(agent_id)).to be false }
        it { is_expected.to be true }
      end

      context 'valid' do
        before { allow(described_class).to receive(:valid_email?).with(agent_id).and_return(true) }

        it { is_expected.to be true }
      end
    end

    context 'Individual' do
      let(:agent_type) { :Individual }

      it { expect(described_class.valid_agent_type?(agent_type)).to be true }
      it { is_expected.to be false }

      context 'any' do
        let(:agent_id) { 'any' }

        it { expect(described_class.valid_individual?(agent_id)).to be false }
        it { is_expected.to be true }
      end

      context 'valid' do
        before { allow(described_class).to receive(:valid_individual?).with(agent_id).and_return(true) }

        it { is_expected.to be true }
      end
    end

    context 'Institution' do
      let(:agent_type) { :Institution }

      it { expect(described_class.valid_agent_type?(agent_type)).to be true }
      it { is_expected.to be false }

      context 'any' do
        let(:agent_id) { 'any' }

        it { expect(described_class.valid_institution?(agent_id)).to be false }
        it { is_expected.to be true }
      end

      context 'valid' do
        before { allow(described_class).to receive(:valid_institution?).with(agent_id).and_return(true) }

        it { expect(described_class.valid_institution?(agent_id)).to be true }
        it { is_expected.to be true }
      end
    end

    context 'User' do
      let(:agent_type) { :User }

      it { expect(described_class.valid_agent_type?(agent_type)).to be true }
      it { is_expected.to be false }

      context 'any' do
        let(:agent_id) { 'any' }

        it { expect(described_class.valid_user?(agent_id)).to be false }
        it { is_expected.to be true }
      end

      context 'valid' do
        before { allow(described_class).to receive(:valid_user?).with(agent_id).and_return(true) }

        it { expect(described_class.valid_user?(agent_id)).to be true }
        it { is_expected.to be true }
      end
    end
  end

  describe '#valid_permission?' do
    subject { described_class.valid_permission?(credential_id) }

    let(:credential_id) { 'credential_id' }

    it { is_expected.to be false }

    context 'read' do
      let(:credential_id) { 'read' }

      it { is_expected.to be true }
    end
  end

  describe '#valid_license_type?' do
    subject { described_class.valid_license_type?(license_type) }

    let(:license_type) { 'license_type' }

    it { is_expected.to be false }

    context 'License' do
      let(:license_type) { 'Greensub::License' }

      it { is_expected.to be true }
    end

    context 'TrialLicense' do
      let(:license_type) { 'Greensub::TrialLicense' }

      it { is_expected.to be true }
    end


    context 'FullLicense' do
      let(:license_type) { 'Greensub::FullLicense' }

      it { is_expected.to be true }
    end

    context 'TrialLicense' do
      let(:license_type) { 'Greensub::TrialLicense' }

      it { is_expected.to be true }
    end
  end
  describe '#valid_credential_type? and #valid_credential?' do
    subject { described_class.valid_credential?(credential_type, credential_id) }

    let(:credential_type) { 'credential_type' }
    let(:credential_id) { 'credential_id' }

    it { expect(described_class.valid_credential_type?(credential_type)).to be false }
    it { is_expected.to be false }

    context 'any' do
      let(:credential_type) { :any }

      it { expect(described_class.valid_credential_type?(credential_type)).to be false }
      it { is_expected.to be false }

      context 'valid' do
        let(:credential_id) { 'any' }

        it { is_expected.to be false }
      end
    end

    context 'License' do
      let(:credential_type) { :License }

      it { expect(described_class.valid_credential_type?(credential_type)).to be true }
      it { expect(described_class.valid_license?(credential_id)).to be false }
      it { is_expected.to be false }

      context 'any' do
        let(:credential_id) { 'any' }

        it { expect(described_class.valid_license?(credential_id)).to be false }
        it { is_expected.to be false }
      end

      context 'valid' do
        before { allow(described_class).to receive(:valid_license?).with(credential_id).and_return(true) }

        it { is_expected.to be true }
      end
    end

    context 'permission' do
      let(:credential_type) { :permission }

      it { expect(described_class.valid_credential_type?(credential_type)).to be true }
      it { expect(described_class.valid_permission?(credential_id)).to be false }
      it { is_expected.to be false }

      context 'any' do
        let(:credential_id) { 'any' }

        it { expect(described_class.valid_permission?(credential_id)).to be false }
        it { is_expected.to be true }
      end

      context 'valid' do
        before { allow(described_class).to receive(:valid_permission?).with(credential_id).and_return(true) }

        it { is_expected.to be true }
      end
    end
  end

  describe '#valid_resource_type? and #valid_resource?' do
    subject { described_class.valid_resource?(resource_type, resource_id) }

    let(:resource_type) { 'resource_type' }
    let(:resource_id) { 'resource_id' }

    it { expect(described_class.valid_resource_type?(resource_type)).to be false }
    it { is_expected.to be false }

    context 'any' do
      let(:resource_type) { :any }

      it { expect(described_class.valid_resource_type?(resource_type)).to be true }
      it { is_expected.to be false }

      context 'valid' do
        let(:resource_id) { 'any' }

        it { is_expected.to be true }
      end
    end

    context 'Component' do
      let(:resource_type) { :Component }

      it { expect(described_class.valid_resource_type?(resource_type)).to be true }
      it { is_expected.to be false }

      context 'any' do
        let(:resource_id) { 'any' }

        it { expect(described_class.valid_component?(resource_id)).to be false }
        it { is_expected.to be true }
      end

      context 'valid' do
        before { allow(described_class).to receive(:valid_component?).with(resource_id).and_return(true) }

        it { is_expected.to be true }
      end
    end

    context 'Product' do
      let(:resource_type) { :Product }

      it { expect(described_class.valid_resource_type?(resource_type)).to be true }
      it { is_expected.to be false }

      context 'any' do
        let(:resource_id) { 'any' }

        it { expect(described_class.valid_product?(resource_id)).to be false }
        it { is_expected.to be true }
      end

      context 'valid' do
        before { allow(described_class).to receive(:valid_product?).with(resource_id).and_return(true) }

        it { expect(described_class.valid_product?(resource_id)).to be true }
        it { is_expected.to be true }
      end
    end
  end

  describe '#valid_actor?' do
    subject { described_class.valid_actor?(actor) }

    let(:actor) { }

    it { is_expected.to be false }

    context 'Anonymous' do
      let(:actor) { Anonymous.new({}) }

      it { is_expected.to be true }
    end

    context 'User' do
      let(:actor) { create(:user) }

      it { is_expected.to be true }
    end

    context 'Guest' do
      let(:actor) { User.guest(user_key: 'wolverine@umich.edu') }

      it { is_expected.to be true }
    end

    context 'Object' do
      let(:actor) { Object.new }

      it { is_expected.to be false }
    end
  end
end
