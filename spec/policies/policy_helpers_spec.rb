# frozen_string_literal: true

require 'rails_helper'

class TestPolicy  < ApplicationPolicy
  include PolicyHelpers
end

RSpec.describe PolicyHelpers do
  let(:policy) { TestPolicy.new(agent, resource) }
  let(:agent) { Anonymous.new({}) }
  let(:resource) { instance_double(Sighrax::Model, 'resource', publisher: publisher) }
  let(:publisher) { instance_double(Sighrax::Publisher, 'publisher', press: press) }
  let(:press) { instance_double(Press, 'press') }

  describe '#can?' do
    subject { policy.send(:can?, action) }

    context 'when invalid action' do
      let(:action) { :action }

      before { allow(agent).to receive(:platform_admin?).and_return true }

      it 'even role of platform admin returns false' do
        is_expected.to be false
      end
    end

    %i[create read update delete].each do |action|
      context "#{action}" do
        let(:action) { action }

        it 'when anonymous always false' do
          is_expected.to be false
        end

        context 'when platform admin' do
          before { allow(agent).to receive(:platform_admin?).and_return true }

          it 'always true' do
            is_expected.to be true
          end
        end

        context 'when another press admin' do
          let(:another_press) { instance_double(Press, 'another_press') }

          before do
            allow(agent).to receive(:presses).and_return [another_press]
            allow(agent).to receive(:admin_presses).and_return [another_press]
          end

          it 'always false' do
            is_expected.to be false
          end
        end

        context 'when from press' do
          before { allow(agent).to receive(:presses).and_return [press] }

          context 'when user' do
            case action
            when :read
              it 'true' do
                is_expected.to be true
              end
            else
              it 'false' do
                is_expected.to be false
              end
            end
          end

          context 'when admin' do
            before { allow(agent).to receive(:admin_presses).and_return [press] }

            it 'always true' do
              is_expected.to be true
            end
          end

          context 'when editor' do
            before { allow(agent).to receive(:editor_presses).and_return([press]) }

            it 'always true' do
              is_expected.to be true
            end
          end

          context 'when analyst' do
            before { allow(agent).to receive(:analyst_presses).and_return([press]) }

            case action
            when :read
              it 'true' do
                is_expected.to be true
              end
            else
              it 'false' do
                is_expected.to be false
              end
            end
          end
        end
      end
    end
  end
end
