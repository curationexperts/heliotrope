require 'rails_helper'

RSpec.describe PressesController, type: :controller do
  describe "#index" do
    context "as a signed in user" do
      let(:user) { create(:user) }
      let!(:press) { create(:press) }
      before { sign_in user }

      it 'shows the presses' do
        get :index
        expect(response).to be_success
        expect(assigns[:presses]).to include press
      end
    end
  end

  describe "#show" do
    context "as a signed in user" do
      let(:user) { create(:user) }
      let!(:press) { create(:press) }
      before { sign_in user }

      it 'shows the press' do
        get :show, id: press
        expect(response).to be_success
        expect(assigns[:press]).to eq press
      end
    end
  end
end
