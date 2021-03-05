# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Pdf Ebooks", type: :request do
  describe '#show' do
    subject { get pdf_ebook_path(pdf_ebook.id) }

    let(:monograph) { create(:public_monograph) }
    let(:pdf_ebook) { create(:public_file_set, content: File.open(File.join(fixture_path, 'hello.pdf'))) }
    let(:featured_representative) { create(:featured_representative, work_id: monograph.id, file_set_id: pdf_ebook.id, kind: 'pdf_ebook') }
    let(:counter_service) { instance_double(CounterService, 'counter_service') }

    before do
      monograph.ordered_members  << pdf_ebook
      monograph.save
      pdf_ebook.save
      featured_representative
      allow(CounterService).to receive(:from).and_return(counter_service)
      allow(counter_service).to receive(:count).with(request: 1)
    end

    it do
      expect { subject }.not_to raise_error
      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:show)
      expect(counter_service).to have_received(:count).with(request: 1)
    end

    context 'when component of product' do
      let(:product) { create(:product) }
      let(:component) { create(:component, identifier: monograph.id, noid: monograph.id) }

      before do
        component.products << product
        component.save
      end

      it do
        expect { subject }.not_to raise_error
        expect(response).to have_http_status(:unauthorized)
        expect(response).not_to render_template(:show)
        expect(counter_service).not_to have_received(:count).with(request: 1)
      end

      context 'when reader license for product' do
        let(:anonymous) { Anonymous.new({}) }
        let(:institution) { create(:institution) }
        let(:license) { create(:full_license) }
        let(:grant) { create(:institution_license_grant,
          agent_id: institution.id,
          credential_id: license.id,
          resource_id: product.id
        ) }

        before do
          allow_any_instance_of(ApplicationController).to receive(:current_actor).and_return(anonymous)
          allow(anonymous).to receive(:institutions).and_return([institution])
          clear_grants_table
          grant
        end

        it do
          expect { subject }.not_to raise_error
          expect(response).to have_http_status(:ok)
          expect(response).to render_template(:show)
          expect(counter_service).to have_received(:count).with(request: 1)
        end
      end
    end
  end
end
