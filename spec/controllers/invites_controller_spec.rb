require 'rails_helper'

RSpec.describe InvitesController, type: :controller do
  render_views
  let (:user) { Fabricate(:user) }

  context 'when invites enabled' do
    before do
      allow(Rails.configuration).to receive(:require_invite) { true }
    end

    describe 'GET #show' do
      context 'when invite is valid' do
        let!(:invite) { Fabricate(:invite, code: 'acode') }
        before do
          get :show, params: {id: invite.code}
        end

        it { expect(assigns(:invite)).to eq(invite) }

        it { expect(response).to render_template(:show) }

        it { is_expected.not_to render_with_layout :application }
      end

      context 'when invite is not valid' do
        it do
          expect {
            get :show, params: {id: 'bad'}
          }.to raise_error ActiveRecord::RecordNotFound
        end
      end
    end

    describe 'GET #new' do
      context 'when logged in' do
        before do
          sign_in(user)
          get :new
        end
        it { expect(response).to have_http_status(:success) }
        it { is_expected.to render_template :new }
      end

      context 'when not logged in' do
        before do
          get :new
        end
        it { expect(response).to have_http_status(:redirect) }
      end
    end

    describe 'POST #create' do
      subject(:perform) { post :create, params: {invite: params} }

      context 'when logged in' do
        before do
          sign_in(user)
        end

        context 'with valid params' do
          let(:params) do
            {
                email: Faker::Internet.email
            }
          end

          specify 'that a record is created' do
            expect { subject }.to change(Invite, :count).by(1)
          end

          describe 'the created invite' do
            before { perform }
            subject { Invite.last }

            its(:email) { is_expected.to eq(params[:email]) }
          end
        end

        context 'with invalid params' do
          let(:params) { {email: 'foo'} }

          specify 'that a record is NOT created' do
            expect { subject }.to_not change(Invite, :count)
          end
        end
      end

      context 'when not logged in' do
        context 'with valid params' do
          let(:params) { {email: 'valid@gov.au'} }

          specify 'that a record is NOT created' do
            expect { subject }.to_not change(Invite, :count)
          end
        end
      end

    end
  end

  context 'when invites disabled' do
    before do
      allow(Rails.configuration).to receive(:require_invite) { false }
    end
    describe 'GET #show' do
      before do
        get :show, params: {id: 'notused'}
      end
      it 'should redirect' do
        expect(response).to redirect_to(root_path)
      end
    end
  end
end
