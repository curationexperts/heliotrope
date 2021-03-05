# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ResourcePolicy do
  let(:policy) { described_class.new(actor, target) }
  let(:actor) { double('actor') }
  let(:target) { double('target') }

  describe '#index?' do
    subject { policy.index? }

    it { is_expected.to be true }
  end

  describe '#show?' do
    subject { policy.show? }

    let(:can_read) { double('can_read') }

    before { allow(policy).to receive(:can?).with(:read).and_return can_read }

    it { expect(ValidationService.valid_action?(:read)).to be true }
    it { is_expected.to be can_read }
  end

  describe '#new?' do
    subject { policy.new? }

    let(:create) { double('create') }

    before { allow(policy).to receive(:create?).and_return create }

    it { is_expected.to be create }
  end

  describe 'create?' do
    subject { policy.create? }

    let(:can_create) { double('can_create') }

    before { allow(policy).to receive(:can?).with(:create).and_return can_create }

    it { expect(ValidationService.valid_action?(:create)).to be true }
    it { is_expected.to be can_create }
  end

  describe 'edit?' do
    subject { policy.edit? }

    let(:update) { double('update') }

    before { allow(policy).to receive(:update?).and_return update }

    it { is_expected.to be update }
  end

  describe 'update?' do
    subject { policy.update? }

    let(:can_update) { double('can_update') }

    before { allow(policy).to receive(:can?).with(:update).and_return can_update }

    it { expect(ValidationService.valid_action?(:update)).to be true }
    it { is_expected.to be can_update }
  end

  describe 'destroy?' do
    subject { policy.destroy? }

    let(:can_delete) { double('can_delete') }

    before { allow(policy).to receive(:can?).with(:delete).and_return can_delete }

    it { expect(ValidationService.valid_action?(:delete)).to be true }
    it { is_expected.to be can_delete }
  end
end
