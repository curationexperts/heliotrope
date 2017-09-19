# frozen_string_literal: true

RSpec.describe EPub::ParagraphPresenter do
  let(:paragraph) { double("paragraph") }

  describe '#new' do
    it 'private_class_method' do
      expect { is_expected }.to raise_error(NoMethodError)
    end
  end

  describe '#html' do
    subject { described_class.send(:new, paragraph).html }
    let(:html) { double("html") }
    let(:safe_html) { double("safe_html") }

    before do
      allow(paragraph).to receive(:html).and_return(html)
      allow(html).to receive(:html_safe).and_return(safe_html)
    end
    it 'returns the paragraph html as safe html' do
      is_expected.to eq safe_html
    end
  end
end