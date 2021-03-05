# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PdfEbookOperationHelpers do
  let(:policy) { described_class.new(actor, pdf_ebook) }
  let(:actor) { Anonymous.new({}) }
  let(:pdf_ebook) { instance_double(Sighrax::PdfEbook, 'pdf_ebook') }

  describe '#accessible_online?' do
    subject { policy.send(:accessible_online?) }

    let(:published) { false }
    let(:tombstone) { false }

    before do
      allow(pdf_ebook).to receive(:published?).and_return published
      allow(pdf_ebook).to receive(:tombstone?).and_return tombstone
    end

    it { is_expected.to be false }

    context 'when published' do
      let(:published) { true }

      it { is_expected.to be true }

      context 'when tombstoned' do
        let(:tombstone) { true }

        it { is_expected.to be false }
      end
    end

    context 'when tombstoned' do
      let(:tombstone) { true }

      it { is_expected.to be false }

      context 'when published' do
        let(:published) { false }

        it { is_expected.to be false }
      end
    end
  end

  describe '#accessible_offline?' do
    subject { policy.send(:accessible_offline?) }

    let(:allow_download) { false }
    let(:accessible_online) { false }

    before do
      allow(pdf_ebook).to receive(:allow_download?).and_return allow_download
      allow(policy).to receive(:accessible_online?).and_return accessible_online
    end

    it { is_expected.to be false }

    context 'when allow download' do
      let(:allow_download) { true }

      it { is_expected.to be false }

      context 'when accessible online' do
        let(:accessible_online) { true }

        it { is_expected.to be true }
      end
    end

    context 'when accessible online' do
      let(:accessible_online) { true }

      it { is_expected.to be false }

      context 'when allow download' do
        let(:allow_download) { true }

        it { is_expected.to be true }
      end
    end
  end

  describe '#unrestricted?' do
    subject { policy.send(:unrestricted?) }

    let(:open_access) { false }
    let(:restricted) { false }

    before do
      allow(pdf_ebook).to receive(:open_access?).and_return open_access
      allow(pdf_ebook).to receive(:restricted?).and_return restricted
    end

    it { is_expected.to be true }

    context 'when open access' do
      let(:open_access) { true }

      it { is_expected.to be true }

      context 'when restricted' do
        let(:restricted) { true }

        it { is_expected.to be true }
      end
    end

    context 'when restricted' do
      let(:restricted) { true }

      it { is_expected.to be false }

      context 'when open access' do
        let(:open_access) { true }

        it { is_expected.to be true }
      end
    end
  end

  describe '#licensed_for?' do
    subject { policy.send(:licensed_for?, entitlement) }

    let(:entitlement) { :entitlement }
    let(:checkpoint) { double('checkpoint') }
    let(:license) { create(:license) }

    before do
      allow(Services).to receive(:checkpoint).and_return checkpoint
      allow(checkpoint).to receive(:licenses_for).with(actor, pdf_ebook).and_return [license]
    end

    it { is_expected.to be false }

    context 'when license entitlement' do
      before { allow(license).to receive(:allows?).with(entitlement).and_return true }

      it { is_expected.to be true }
    end
  end
end
