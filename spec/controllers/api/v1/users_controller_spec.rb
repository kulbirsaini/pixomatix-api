require 'rails_helper'

RSpec.describe Api::V1::UsersController, type: :controller do
  context "update" do
    context "with no email and no token" do
      it "responds with invalid session" do
        put :update
        expect(response).to have_http_status(401)
        expect(notice).to eq(scoped_t('base.invalid_session'))
      end
    end

    context "with invalid email and invalid token" do
      it "responds with invalid session" do
        user = create(:user)
        user.confirm!
        user.unlock!
        request.headers['X-Access-Email'] = 'test@example.com'
        request.headers['X-Access-Token'] = 'basdfsadfqwefasdf'
        put :update
        expect(response).to have_http_status(401)
        expect(notice).to eq(scoped_t('base.invalid_session'))
      end
    end

    context "with valid email and invalid token" do
      it "responds with invalid session" do
        user = create(:user)
        user.confirm!
        user.unlock!
        request.headers['X-Access-Email'] = user.email
        request.headers['X-Access-Token'] = 'basdfsadfqwefasdf'
        put :update
        expect(response).to have_http_status(401)
        expect(notice).to eq(scoped_t('base.invalid_session'))
      end
    end

    context "with invalid email and valid token" do
      it "responds with invalid session" do
        user = create(:user)
        user.confirm!
        user.unlock!
        token = user.issue_token

        user.reload
        request.headers['X-Access-Token'] = token
        request.headers['X-Access-Email'] = 'test@example.com'
        put :update
        expect(response).to have_http_status(401)
        expect(notice).to eq(scoped_t('base.invalid_session'))
      end
    end

    context "with valid email and valid token" do
      context "with no data" do
        it "responds with updated successfully" do
          user = create(:user)
          user.confirm!
          user.unlock!
          token = user.issue_token

          request.headers['X-Access-Token'] = token
          request.headers['X-Access-Email'] = user.email
          put :update
          expect(response).to have_http_status(200)
          expect(notice).to eq(scoped_t('users.update_success'))

          user.reload
        end
      end

      context "with invalid data" do
        it "responds with password reset failed" do
          user = create(:user)
          user.confirm!
          user.unlock!
          token = user.issue_token

          request.headers['X-Access-Token'] = token
          request.headers['X-Access-Email'] = user.email
          user_params = { name: 'New Name', password: '123456789', password_confirmation: '12345678' }
          put :update, user: user_params
          expect(response).to have_http_status(422)
          expect(notice).to eq(scoped_t('users.update_failed'))

          user.reload
          expect(user.name).not_to eq(user_params['name'])
        end
      end

      context "with valid data" do
        it "responds with updated successfully" do
          user = create(:user)
          user.confirm!
          user.unlock!
          token = user.issue_token
          encrypted_password = user.encrypted_password
          new_password = '123456789'
          password_salt = user.password_salt

          expect(user.tokens).not_to eq({})

          request.headers['X-Access-Token'] = token
          request.headers['X-Access-Email'] = user.email

          user_params = { name: 'New Name', password: new_password, password_confirmation: new_password }
          put :update, user: user_params
          expect(response).to have_http_status(200)
          expect(notice).to eq(scoped_t('users.update_success'))

          user.reload
          expect(user.encrypted_password).not_to eq(encrypted_password)
          expect(user.password_salt).not_to eq(password_salt)
          expect(user.encrypted_password).to eq(BCrypt::Engine.hash_secret(new_password, user.password_salt))
          expect(user.name).to eq(user_params[:name])
        end
      end

      context "with valid data and email" do
        it "responds with updated successfully" do
          user = create(:user)
          user.confirm!
          user.unlock!
          email = user.email
          token = user.issue_token
          encrypted_password = user.encrypted_password
          new_password = '123456789'
          password_salt = user.password_salt

          expect(user.tokens).not_to eq({})

          request.headers['X-Access-Token'] = token
          request.headers['X-Access-Email'] = user.email

          user_params = { name: 'New Name', email: 'new@example.com', password: new_password, password_confirmation: new_password }
          put :update, user: user_params
          expect(response).to have_http_status(200)
          expect(notice).to eq(scoped_t('users.update_success'))

          user.reload
          expect(user.encrypted_password).not_to eq(encrypted_password)
          expect(user.password_salt).not_to eq(password_salt)
          expect(user.encrypted_password).to eq(BCrypt::Engine.hash_secret(new_password, user.password_salt))
          expect(user.name).to eq(user_params[:name])
          expect(user.email).not_to eq(user_params[:email])
          expect(user.email).to eq(email)
        end
      end
    end
  end # update

  context "destroy" do
    context "with no email and no token" do
      it "responds with invalid session" do
        delete :destroy
        expect(response).to have_http_status(401)
        expect(notice).to eq(scoped_t('base.invalid_session'))
      end
    end

    context "with invalid email and invalid token" do
      it "responds with invalid session" do
        user = create(:user)
        user.confirm!
        user.unlock!
        request.headers['X-Access-Email'] = 'test@example.com'
        request.headers['X-Access-Token'] = 'basdfsadfqwefasdf'
        delete :destroy
        expect(response).to have_http_status(401)
        expect(notice).to eq(scoped_t('base.invalid_session'))
      end
    end

    context "with valid email and invalid token" do
      it "responds with invalid session" do
        user = create(:user)
        user.confirm!
        user.unlock!
        request.headers['X-Access-Email'] = user.email
        request.headers['X-Access-Token'] = 'basdfsadfqwefasdf'
        delete :destroy
        expect(response).to have_http_status(401)
        expect(notice).to eq(scoped_t('base.invalid_session'))
      end
    end

    context "with invalid email and valid token" do
      it "responds with invalid session" do
        user = create(:user)
        user.confirm!
        user.unlock!
        token = user.issue_token

        user.reload
        request.headers['X-Access-Token'] = token
        request.headers['X-Access-Email'] = 'test@example.com'
        delete :destroy
        expect(response).to have_http_status(401)
        expect(notice).to eq(scoped_t('base.invalid_session'))
      end
    end

    context "with valid email and valid token" do
      context "with no data" do
        it "responds with registration cancelled successfully" do
          user = create(:user)
          user.confirm!
          user.unlock!
          email = user.email
          token = user.issue_token

          request.headers['X-Access-Token'] = token
          request.headers['X-Access-Email'] = user.email
          delete :destroy
          expect(response).to have_http_status(200)
          expect(notice).to eq(scoped_t('users.cancel_success'))

          user = User.where(email: email).first
          expect(user).to be_nil
        end
      end

      context "with data" do
        it "responds with registration cancelled successfully" do
          user = create(:user)
          user.confirm!
          user.unlock!
          email = user.email
          token = user.issue_token

          request.headers['X-Access-Token'] = token
          request.headers['X-Access-Email'] = user.email
          user_params = { name: 'New Name', password: '123456789', password_confirmation: '123456789' }
          delete :destroy, user: user_params
          expect(response).to have_http_status(200)
          expect(notice).to eq(scoped_t('users.cancel_success'))

          user = User.where(email: email).first
          expect(user).to be_nil
        end
      end
    end
  end # destroy
end
