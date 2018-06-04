# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User do
  describe '#user_key' do
    subject { user.user_key }
    let(:user) { described_class.new(email: 'foo@example.com') }
    it { is_expected.to eq 'foo@example.com' }
  end

  describe "#total_file_views" do
    subject { user.total_file_views }
    let(:user) { create(:user) }
    it { is_expected.to eq 0 }
  end

  describe '#role?' do
    subject { user.role? }

    let(:user) { create(:user) }

    before { Role.delete_all }

    it { is_expected.to be false }

    context 'role' do
      let(:role) { create(:role, user: user) }

      before { role }

      it { is_expected.to be true }
    end
  end

  describe '#presses' do
    subject { user.presses }

    let(:press1) { create(:press) }
    let(:press2) { create(:press) }
    let(:press3) { create(:press) }
    let(:user) { create(:user) }

    before do
      create(:role, resource: press1, user: user, role: 'admin')
      create(:role, resource: press2, user: user, role: 'admin')
    end

    it { is_expected.to eq [press1, press2] }
  end

  describe '#admin_presses' do
    let(:press1) { create(:press) }
    let(:press2) { create(:press) }

    let(:user) { create(:user) }
    let(:superuser) { create(:platform_admin) }

    before do
      Press.delete_all
      Role.delete_all
      create(:role, resource: press1, user: user, role: 'editor')
      create(:role, resource: press2, user: user, role: 'admin')
    end

    it 'returns the presses that this user is an admin for' do
      expect(user.admin_presses).to eq [press2]
      expect(superuser.admin_presses).to eq [press1, press2]
    end
  end

  describe '#platform_admin?' do
    subject { user.platform_admin? }

    context "when a platform admin" do
      let(:user) { create(:platform_admin) }
      it { is_expected.to be true }
    end

    context "when a press admin" do
      let(:user) { create(:press_admin) }
      it { is_expected.to be false }
    end
  end

  describe '#groups' do
    let(:press1) { create(:press, subdomain: 'red') }
    let(:press2) { create(:press, subdomain: 'blue') }

    let(:admin) { create(:user) }
    let(:editor) { create(:user) }
    let(:platform_admin) { create(:platform_admin) }

    before do
      Press.delete_all
      Role.delete_all
      create(:role, resource: press1, user: admin, role: 'admin')
      create(:role, resource: press2, user: editor, role: 'editor')
    end

    it "returns the right groups for users" do
      expect(admin.groups).to eq ["red_admin"]
      expect(editor.groups).to eq ["blue_editor"]
      expect(platform_admin.groups).to eq ["blue_admin", "blue_editor", "red_admin", "red_editor", "admin"]
    end
  end

  describe '#token' do
    subject { user.token }
    let(:user) { build(:user) }
    it { is_expected.to eq(JsonWebToken.encode(email: user.email, pin: user.encrypted_password)) }
  end

  describe '#tokenize!' do
    let(:user) { build(:user) }
    it do
      old_token = user.token
      user.tokenize!
      expect(user.token).not_to eq(old_token)
      expect(user.token).to eq(JsonWebToken.encode(email: user.email, pin: user.encrypted_password))
    end
  end

  describe '#guest' do
    subject { described_class.guest(user_key: email) }

    let(:email) { 'wolverine@umich.edu' }

    it { is_expected.to be_a_kind_of(described_class) }

    it { is_expected.to be_an_instance_of(Guest) }

    it { expect(subject.email).to eq(email) }
  end
end
