# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PdfEbookPolicy do
  describe '#show?' do
    subject { policy.show? }

    let(:policy) { described_class.new(actor, pdf_ebook, share) }
    let(:actor) { Anonymous.new({}) }
    let(:pdf_ebook) { instance_double(Sighrax::PdfEbook, 'pdf_ebook') }
    let(:share) { false }
    let(:reader_op) { instance_double(PdfEbookReaderOperation, 'reader_op', allowed?: allowed) }
    let(:allowed) { false }

    before { allow(PdfEbookReaderOperation).to receive(:new).with(actor, pdf_ebook).and_return reader_op }

    it { is_expected.to be false }

    context 'when share' do
      let(:share) { true }

      it { is_expected.to be true }
    end

    context 'when allowed' do
      let(:allowed) { true }

      it { is_expected.to be true }
    end
  end
end
