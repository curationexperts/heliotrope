# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PdfEbookReaderOperation do
  describe '#allowed?' do
    subject { policy.allowed? }

    let(:policy) { described_class.new(actor, pdf_ebook) }
    let(:actor) { Anonymous.new({}) }
    let(:pdf_ebook) { instance_double(Sighrax::PdfEbook, 'pdf_ebook') }
    let(:can_read) { false }
    let(:accessible_online) { false }
    let(:unrestricted) { false }
    let(:licensed_for_reader) { false }

    before do
      allow(policy).to receive(:can?).with(:read).and_return can_read
      allow(policy).to receive(:accessible_online?).and_return accessible_online
      allow(policy).to receive(:unrestricted?).and_return unrestricted
      allow(policy).to receive(:licensed_for?).with(:reader).and_return licensed_for_reader
    end

    it { is_expected.to be false }

    context 'when can read' do
      let(:can_read) { true }

      it { is_expected.to be true }
    end

    context 'when accessible online' do
      let(:accessible_online) { true }

      it { is_expected.to be false }

      context 'when unrestricted' do
        let(:unrestricted) { true }

        it { is_expected.to be true }
      end

      context 'when licensed for reader' do
        let(:licensed_for_reader) { true }

        it { is_expected.to be true }
      end
    end

    context 'when unrestricted' do
      let(:unrestricted) { true }

      it { is_expected.to be false }
    end

    context 'when licensed for reader' do
      let(:licensed_for_reader) { true }

      it { is_expected.to be false }
    end
  end
end
