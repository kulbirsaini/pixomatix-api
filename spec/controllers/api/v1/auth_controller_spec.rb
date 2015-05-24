require 'rails_helper'

def get_auth_token_for(user, password = '12345678')
  user.confirm!
  user.unlock!
  post :login, user: { email: user.email, password: password }
  json['token']
end

def authenticate_user_and_set_headers(user, password = '12345678')
  token = get_auth_token_for(user, password)
  request.headers['X-Access-Token'] = token
  request.headers['X-Access-Email'] = user.email
end

RSpec.describe Api::V1::AuthController, type: :controller do
  context "register" do
    context "without data" do
      it "responds with registration failed" do
        post :register
        expect(response).to have_http_status(422)
        expect(notice).to eq(scoped_t('auth.registration_failed'))
      end
    end

    context "with invalid data" do
      it "responds with registration failed" do
        post :register, { user: { email: 'text@example', name: 'Kulbir Saini', password: '1234', password_confirmation: '1234' } }
        expect(response).to have_http_status(422)
        expect(notice).to eq(scoped_t('auth.registration_failed'))
        expect(json['user']).to be_nil
      end
    end

    context "with valid data" do
      it "responds with registration successful" do
        user_params = { email: 'text@example.com', name: 'Kulbir Saini', password: '1234567', password_confirmation: '1234567' }
        post :register, user: user_params
        expect(response).to have_http_status(200)
        expect(notice).to eq(scoped_t('auth.registered_successfully'))
        user = User.where(email: user_params[:email]).first
        expect(user).to be_present
        expect(user.confirmed_at).to be_nil
        expect(user.confirmation_token).to be_present
        expect(user.tokens).to eq({})
        expect(user.locked_at).to be_nil
        expect(json['user']['name']).to eq(user_params[:name])
      end
    end

    context "with unlocked and unconfirmed user" do
      it "responds with already registered" do
        user = create(:unconfirmed_user)
        user.unlock!
        user_params = { email: user.email }
        post :register, user: user_params
        expect(response).to have_http_status(401)
        expect(notice).to eq(scoped_t('auth.registered_and_unconfirmed'))
        user = User.where(email: user_params[:email]).first
        expect(user).to be_present
        expect(user.confirmed_at).to be_nil
        expect(user.confirmation_token).to be_present
        expect(user.tokens).to eq({})
        expect(user.locked_at).to be_nil
        expect(json['user']).to be_nil
      end
    end

    context "with locked and unconfirmed user" do
      it "responds with already registered" do
        user = create(:unconfirmed_user)
        user.lock!
        user_params = { email: user.email }
        post :register, user: user_params
        expect(response).to have_http_status(401)
        expect(notice).to eq(scoped_t('auth.registered_and_unconfirmed'))
        user = User.where(email: user_params[:email]).first
        expect(user).to be_present
        expect(user.confirmed_at).to be_nil
        expect(user.confirmation_token).to be_present
        expect(user.tokens).to eq({})
        expect(user.locked_at).to be_present
        expect(json['user']).to be_nil
      end
    end

    context "with unlocked and confirmed user" do
      it "responds with already registered" do
        user = create(:user)
        user.confirm!
        user.unlock!
        user_params = { email: user.email }
        post :register, user: user_params
        expect(response).to have_http_status(401)
        expect(notice).to eq(scoped_t('auth.registered_already'))
        user = User.where(email: user_params[:email]).first
        expect(user).to be_present
        expect(user.confirmed_at).to be_present
        expect(user.confirmation_token).to be_nil
        expect(user.tokens).to eq({})
        expect(user.locked_at).to be_nil
        expect(json['user']).to be_nil
      end
    end

    context "with locked and confirmed user" do
      it "responds with already registered" do
        user = create(:confirmed_user)
        user.confirm!
        user.lock!
        user_params = { email: user.email }
        post :register, user: user_params
        expect(response).to have_http_status(401)
        expect(notice).to eq(scoped_t('auth.registered_already'))
        user = User.where(email: user_params[:email]).first
        expect(user).to be_present
        expect(user.confirmed_at).to be_present
        expect(user.confirmation_token).to be_nil
        expect(user.tokens).to eq({})
        expect(user.locked_at).to be_present
        expect(json['user']).to be_nil
      end
    end
  end # register

  context "login" do
    context "with no data" do
      it "responds with invalid credentials" do
        post :login
        expect(response).to have_http_status(401)
        expect(notice).to eq(scoped_t('auth.invalid_credentials'))
        expect(json['user']).to be_nil
      end
    end

    context "with invalid data" do
      it "responds with invalid credentials" do
        user = create(:user)
        post :login, { user: { email: 'test@example.com', password: '12345678' } }
        expect(response).to have_http_status(401)
        expect(notice).to eq(scoped_t('auth.invalid_credentials'))
        expect(json['user']).to be_nil
      end
    end

    context "with locked user" do
      it "responds with user locked" do
        user = create(:user)
        user.lock!
        user_params = { email: user.email, password: '12345678' }
        post :login, user: user_params
        expect(response).to have_http_status(401)
        expect(notice).to eq(scoped_t('auth.user_locked'))
        expect(json['user']).to be_nil
      end
    end

    context "with unconfirmed user" do
      it "responds with user not confirmed" do
        user = create(:user)
        user.unconfirm!
        user_params = { email: user.email, password: '12345678' }
        post :login, user: user_params
        expect(response).to have_http_status(401)
        expect(notice).to eq(scoped_t('auth.user_not_confirmed'))
        expect(json['user']).to be_nil
      end
    end

    context "with valid user" do
      it "responds with authentication token" do
        user = create(:user)
        user.confirm!
        user.unlock!
        user_params = { email: user.email, password: '12345678' }
        post :login, user: user_params
        expect(response).to have_http_status(200)
        expect(notice).to eq(scoped_t('auth.login_success'))
        user.reload
        expect(json['user']).to be_present
        expect(json['user']['name']).to eq(user.name)
        expect(json['user']['email']).to eq(user.email)
        expect(json['token']).to be_present
        expect(user.tokens.keys).to include(json['token'])
      end
    end
  end # login

  context "user" do
    context "with no token" do
      it "responds with invalid session" do
        get :user
        expect(response).to have_http_status(401)
        expect(notice).to eq(scoped_t('base.invalid_session'))
        expect(json['user']).to be_nil
      end
    end

    context "with invalid token" do
      it "responds with invalid session" do
        user = create(:user)
        authenticate_user_and_set_headers(user)
        request.headers['X-Access-Token'] = 'abcd'
        get :user
        expect(response).to have_http_status(401)
        expect(notice).to eq(scoped_t('base.invalid_session'))
        expect(json['user']).to be_nil
      end
    end

    context "with invalid email" do
      it "responds with invalid session" do
        user = create(:user)
        authenticate_user_and_set_headers(user)
        request.headers['X-Access-Email'] = 'abcd@asinic.on'
        get :user
        expect(response).to have_http_status(401)
        expect(notice).to eq(scoped_t('base.invalid_session'))
        expect(json['user']).to be_nil
      end
    end

    context "with valid token" do
      it "responds with invalid session" do
        user = create(:user)
        authenticate_user_and_set_headers(user)

        get :user
        expect(response).to have_http_status(200)
        expect(notice).to be_nil
        expect(json['user']).to be_present
        expect(json['user']['name']).to eq(user.name)
        expect(json['user']['email']).to eq(user.email)
      end
    end
  end # user

  context "logout" do
    context "when not logged in" do
      it "responds with invalid session" do
        delete :logout
        expect(response).to have_http_status(401)
        expect(notice).to eq(scoped_t('base.invalid_session'))
      end
    end

    context "with invalid token" do
      it "responds with invalid session" do
        user = create(:user)
        authenticate_user_and_set_headers(user)
        request.headers['X-Access-Token'] = 'asdfb'
        delete :logout
        expect(response).to have_http_status(401)
        expect(notice).to eq(scoped_t('base.invalid_session'))
      end
    end

    context "with invalid email" do
      it "responds with invalid session" do
        user = create(:user)
        authenticate_user_and_set_headers(user)
        request.headers['X-Access-Email'] = 'asdfb'
        delete :logout
        expect(response).to have_http_status(401)
        expect(notice).to eq(scoped_t('base.invalid_session'))
      end
    end

    context "when logged in" do
      it "responds with logged out successfully" do
        user = create(:user)
        authenticate_user_and_set_headers(user)
        delete :logout
        expect(response).to have_http_status(200)
        expect(notice).to eq(scoped_t('auth.logout_success'))
      end
    end
  end # logout

  context "validate" do
    context 'with no token' do
      it "responds with token invalid" do
        get :validate
        expect(response).to have_http_status(401)
        expect(notice).to eq(scoped_t('auth.token_invalid'))
        expect(json['user']).to be_nil
      end
    end

    context "with invalid token" do
      it "responds with token invalid" do
        user = create(:user)
        authenticate_user_and_set_headers(user)
        request.headers['X-Access-Token'] = 'abcd'
        get :validate
        expect(response).to have_http_status(401)
        expect(notice).to eq(scoped_t('auth.token_invalid'))
        expect(json['user']).to be_nil
      end
    end

    context "with invalid email" do
      it "responds with invalid token" do
        user = create(:user)
        authenticate_user_and_set_headers(user)
        request.headers['X-Access-Email'] = 'abcd@asinic.on'
        get :validate
        expect(response).to have_http_status(401)
        expect(notice).to eq(scoped_t('auth.token_invalid'))
        expect(json['user']).to be_nil
      end
    end

    context "with valid token" do
      it "responds with invalid session" do
        user = create(:user)
        authenticate_user_and_set_headers(user)

        get :validate
        expect(response).to have_http_status(200)
        expect(notice).to eq(scoped_t('auth.token_valid'))
        expect(json['user']).to be_present
        expect(json['user']['name']).to eq(user.name)
        expect(json['user']['email']).to eq(user.email)
      end
    end
  end # validate

  context "reset_password_instructions" do
    context "with valid email" do
      context "and without reset password token" do
        it "should send reset password instructions" do
          user = create(:user_without_reset_password_token)
          reset_password_token = user.reset_password_token
          get :reset_password_instructions, { user: { email: 'user@example.com' } }
          expect(response).to have_http_status(200)
          expect(notice).to eq(scoped_t('auth.reset_password_sent'))
          user.reload
          expect(reset_password_token).to be_nil
          expect(user.reset_password_token).to be_present
          expect(user.reset_password_token).not_to eq(reset_password_token)
        end
      end

      context "and with reset password token" do
        it "should send reset password instructions" do
          user = create(:user_with_reset_password_token)
          reset_password_token = user.reset_password_token
          get :reset_password_instructions, { user: { email: 'user@example.com' } }
          expect(response).to have_http_status(200)
          expect(notice).to eq(scoped_t('auth.reset_password_sent'))
          user.reload
          expect(reset_password_token).to be_present
          expect(user.reset_password_token).to be_present
          expect(user.reset_password_token).not_to eq(reset_password_token)
        end
      end
    end

    context "with invalid email" do
      it "responds with cannot reset password" do
        get :reset_password_instructions, { user: { email: 'confirmed@example.com' } }
        expect(response).to have_http_status(422)
        expect(notice).to eq(scoped_t('auth.cannot_reset_password'))
      end
    end

    context "with no email" do
      it "responds with cannot reset password" do
        get :reset_password_instructions
        expect(response).to have_http_status(422)
        expect(notice).to eq(scoped_t('auth.cannot_reset_password'))
      end
    end
  end # reset_password_instructions

  context "reset_password" do
    context "with no email and no token" do
      it "responds with invalid email or password token" do
        post :reset_password
        expect(response).to have_http_status(401)
        expect(notice).to eq(scoped_t('auth.invalid_email_or_password_token'))
      end
    end

    context "with invalid email and invalid token" do
      it "responds with invalid email or password token" do
        user = create(:user)
        user.confirm!
        user.unlock!
        request.headers['X-Access-Email'] = 'test@example.com'
        request.headers['X-Access-Reset-Password-Token'] = 'basdfsadfqwefasdf'
        post :reset_password
        expect(response).to have_http_status(401)
        expect(notice).to eq(scoped_t('auth.invalid_email_or_password_token'))
      end
    end

    context "with valid email and invalid token" do
      it "responds with invalid email or password token" do
        user = create(:user)
        user.confirm!
        user.unlock!
        request.headers['X-Access-Email'] = user.email
        request.headers['X-Access-Reset-Password-Token'] = 'basdfsadfqwefasdf'
        post :reset_password
        expect(response).to have_http_status(401)
        expect(notice).to eq(scoped_t('auth.invalid_email_or_password_token'))
      end
    end

    context "with invalid email and valid token" do
      it "responds with invalid email or password token" do
        user = create(:user)
        user.confirm!
        user.unlock!

        get :reset_password_instructions, user: { email: user.email }
        expect(response).to have_http_status(200)

        user.reload
        request.headers['X-Access-Reset-Password-Token'] = user.reset_password_token
        request.headers['X-Access-Email'] = 'test@example.com'
        post :reset_password
        expect(response).to have_http_status(401)
        expect(notice).to eq(scoped_t('auth.invalid_email_or_password_token'))
      end
    end

    context "with valid email and valid token" do
      context "with no password" do
        it "responds with password reset failed" do
          user = create(:user)
          user.confirm!
          user.unlock!
          encrypted_password = user.encrypted_password

          get :reset_password_instructions, user: { email: user.email }
          expect(response).to have_http_status(200)

          user.reload
          reset_password_token = user.reset_password_token
          request.headers['X-Access-Reset-Password-Token'] = reset_password_token
          request.headers['X-Access-Email'] = user.email
          post :reset_password
          expect(response).to have_http_status(422)
          expect(notice).to eq(scoped_t('auth.password_reset_failed'))

          user.reload
          expect(user.encrypted_password).to eq(encrypted_password)
          expect(user.reset_password_token).to eq(reset_password_token)
        end
      end

      context "with invalid password" do
        it "responds with password reset failed" do
          user = create(:user)
          user.confirm!
          user.unlock!
          encrypted_password = user.encrypted_password

          get :reset_password_instructions, user: { email: user.email }
          expect(response).to have_http_status(200)

          user.reload
          reset_password_token = user.reset_password_token
          request.headers['X-Access-Reset-Password-Token'] = reset_password_token
          request.headers['X-Access-Email'] = user.email
          post :reset_password, user: { password: '123456789', password_confirmation: '12345678' }
          expect(response).to have_http_status(422)
          expect(notice).to eq(scoped_t('auth.password_reset_failed'))

          user.reload
          expect(user.encrypted_password).to eq(encrypted_password)
          expect(user.reset_password_token).to eq(reset_password_token)
        end
      end

      context "with valid password" do
        it "responds with password reset successfully" do
          user = create(:user)
          user.confirm!
          user.unlock!
          user.issue_token
          encrypted_password = user.encrypted_password
          new_password = '123456789'
          password_salt = user.password_salt

          expect(user.tokens).not_to eq({})

          get :reset_password_instructions, user: { email: user.email }
          expect(response).to have_http_status(200)

          user.reload
          reset_password_token = user.reset_password_token
          request.headers['X-Access-Reset-Password-Token'] = reset_password_token
          request.headers['X-Access-Email'] = user.email
          post :reset_password, user: { password: new_password, password_confirmation: new_password }
          expect(response).to have_http_status(200)
          expect(notice).to eq(scoped_t('auth.password_reset_success'))

          user.reload
          expect(user.encrypted_password).not_to eq(encrypted_password)
          expect(user.reset_password_token).to be_nil
          expect(user.password_salt).not_to eq(password_salt)
          expect(user.encrypted_password).to eq(BCrypt::Engine.hash_secret(new_password, user.password_salt))
          expect(location).to be_present
          expect(user.tokens).to eq({})
        end
      end
    end
  end # reset_password

  context "unlock_instructions" do
    context "with valid email" do
      context "with locked account" do
        context "with unlock token" do
          it "should send unlock instructions" do
            user = create(:locked_user_without_unlock_token)
            unlock_token = user.unlock_token
            get :unlock_instructions, { user: { email: 'locked@example.com' } }
            expect(response).to have_http_status(200)
            expect(notice).to eq(scoped_t('auth.unlock_sent'))
            user.reload
            expect(unlock_token).to be_nil
            expect(user.unlock_token).to be_present
            expect(user.unlock_token).not_to eq(unlock_token)
          end
        end

        context "without unlock token" do
          it "should send unlock instructions" do
            user = create(:locked_user_with_unlock_token)
            unlock_token = user.unlock_token
            get :unlock_instructions, { user: { email: 'locked@example.com' } }
            expect(response).to have_http_status(200)
            expect(notice).to eq(scoped_t('auth.unlock_sent'))
            user.reload
            expect(unlock_token).to be_present
            expect(user.unlock_token).to be_present
            expect(user.unlock_token).not_to eq(unlock_token)
          end
        end
      end

      context "with unlocked account" do
        it "responds with cannot unlock" do
          user = create(:unlocked_user)
          user.unlock!
          expect(user.locked_at).to be_nil
          get :unlock_instructions, { user: { email: 'unlocked@example.com' } }
          expect(response).to have_http_status(422)
          expect(notice).to eq(scoped_t('auth.cannot_unlock'))
          expect(user.unlock_token).to be_nil
          expect(user.locked_at).to be_nil
        end
      end


      context "with invalid email" do
        it "responds with cannot unlock account" do
          get :unlock_instructions, { user: { email: 'unlocked@example.com' } }
          expect(response).to have_http_status(422)
          expect(notice).to eq(scoped_t('auth.cannot_unlock'))
        end
      end

      context "with no email" do
        it "responds with cannot unlock account" do
          get :unlock_instructions
          expect(response).to have_http_status(422)
          expect(notice).to eq(scoped_t('auth.cannot_unlock'))
        end
      end
    end
  end # unlock_instructions

  context "unlock" do
    context "with no email and no token" do
      it "responds with invalid email or unlock token" do
        post :unlock
        expect(response).to have_http_status(401)
        expect(notice).to eq(scoped_t('auth.invalid_email_or_unlock_token'))
      end
    end

    context "with invalid email and invalid token" do
      it "responds with invalid email or unlock token" do
        user = create(:user)
        user.confirm!
        user.lock!
        request.headers['X-Access-Email'] = 'test@example.com'
        request.headers['X-Access-Unlock-Token'] = 'basdfsadfqwefasdf'
        post :unlock
        expect(response).to have_http_status(401)
        expect(notice).to eq(scoped_t('auth.invalid_email_or_unlock_token'))
      end
    end

    context "with valid email and invalid token" do
      it "responds with invalid email or unlock token" do
        user = create(:user)
        user.confirm!
        user.lock!
        request.headers['X-Access-Email'] = user.email
        request.headers['X-Access-Unlock-Token'] = 'basdfsadfqwefasdf'
        post :unlock
        expect(response).to have_http_status(401)
        expect(notice).to eq(scoped_t('auth.invalid_email_or_unlock_token'))
      end
    end

    context "with invalid email and valid token" do
      it "responds with invalid email or unlock token" do
        user = create(:user)
        user.confirm!
        user.lock!

        get :unlock_instructions, user: { email: user.email }
        expect(response).to have_http_status(200)

        user.reload
        request.headers['X-Access-Unlock-Token'] = user.unlock_token
        request.headers['X-Access-Email'] = 'test@example.com'
        post :unlock
        expect(response).to have_http_status(401)
        expect(notice).to eq(scoped_t('auth.invalid_email_or_unlock_token'))
      end
    end

    context "with valid email and valid token" do
      it "responds with unlocked successfully" do
        user = create(:user)
        user.confirm!
        user.update failed_attempts: 10
        user.lock!

        get :unlock_instructions, user: { email: user.email }
        expect(response).to have_http_status(200)

        user.reload
        unlock_token = user.unlock_token
        request.headers['X-Access-Unlock-Token'] = unlock_token
        request.headers['X-Access-Email'] = user.email
        post :unlock
        expect(response).to have_http_status(200)
        expect(notice).to eq(scoped_t('auth.unlock_success'))

        user.reload
        expect(user.unlock_token).to be_nil
        expect(user.locked_at).to be_nil
        expect(user.failed_attempts).to eq(0)
        expect(location).to be_present
      end
    end
  end # unlock

  context "confirmation_instructions" do
    context "with valid email" do
      context "with unconfirmed account" do
        context "with confirmation token" do
          it "should send confirmation instructions" do
            user = create(:unconfirmed_user_with_confirmation_token)
            confirmation_token = user.confirmation_token
            get :confirmation_instructions, { user: { email: 'unconfirmed@example.com' } }
            expect(response).to have_http_status(200)
            expect(notice).to eq(scoped_t('auth.confirmation_sent'))
            user.reload
            expect(confirmation_token).to be_present
            expect(user.confirmation_token).to be_present
            expect(user.confirmation_token).not_to eq(confirmation_token)
            expect(user.confirmed_at).to be_nil
          end
        end

        context "without confirmation token" do
          it "should send confirmation instructions" do
            user = create(:unconfirmed_user_without_confirmation_token)
            confirmation_token = user.confirmation_token
            get :confirmation_instructions, { user: { email: 'unconfirmed@example.com' } }
            expect(response).to have_http_status(200)
            expect(notice).to eq(scoped_t('auth.confirmation_sent'))
            user.reload
            expect(confirmation_token).to be_present
            expect(user.confirmation_token).to be_present
            expect(user.confirmation_token).not_to eq(confirmation_token)
            expect(user.confirmed_at).to be_nil
          end
        end
      end

      context "with confirmed account" do
        it "responds with cannot confirm" do
          user = create(:confirmed_user)
          user.confirm!
          get :confirmation_instructions, { user: { email: 'confirmed@example.com' } }
          expect(response).to have_http_status(422)
          expect(notice).to eq(scoped_t('auth.cannot_confirm'))
          expect(user).to be_present
          expect(user.confirmed_at).to be_present
          expect(user.confirmation_token).to be_nil
        end
      end
    end

    context "with invalid email" do
      it "responds with cannot confirm account" do
        get :confirmation_instructions, { user: { email: 'confirmed@example.com' } }
        expect(response).to have_http_status(422)
        expect(notice).to eq(scoped_t('auth.cannot_confirm'))
      end
    end

    context "with no email" do
      it "responds with cannot confirm account" do
        get :confirmation_instructions
        expect(response).to have_http_status(422)
        expect(notice).to eq(scoped_t('auth.cannot_confirm'))
      end
    end
  end # confirmation_instructions

  context "confirm" do
    context "with no email and no token" do
      it "responds with invalid email or confirmation token" do
        post :confirm
        expect(response).to have_http_status(401)
        expect(notice).to eq(scoped_t('auth.invalid_email_or_confirmation_token'))
      end
    end

    context "with invalid email and invalid token" do
      it "responds with invalid email or confirmation token" do
        user = create(:user)
        request.headers['X-Access-Email'] = 'test@example.com'
        request.headers['X-Access-Confirmation-Token'] = 'basdfsadfqwefasdf'
        post :confirm
        expect(response).to have_http_status(401)
        expect(notice).to eq(scoped_t('auth.invalid_email_or_confirmation_token'))
      end
    end

    context "with valid email and invalid token" do
      it "responds with invalid email or confirmation token" do
        user = create(:user)
        request.headers['X-Access-Email'] = user.email
        request.headers['X-Access-Confirmation-Token'] = 'basdfsadfqwefasdf'
        post :confirm
        expect(response).to have_http_status(401)
        expect(notice).to eq(scoped_t('auth.invalid_email_or_confirmation_token'))
      end
    end

    context "with invalid email and valid token" do
      it "responds with invalid email or confirmation token" do
        user = create(:user)
        user.unconfirm!

        get :confirmation_instructions, user: { email: user.email }
        expect(response).to have_http_status(200)

        user.reload
        request.headers['X-Access-Confirmation-Token'] = user.confirmation_token
        request.headers['X-Access-Email'] = 'test@example.com'
        post :confirm
        expect(response).to have_http_status(401)
        expect(notice).to eq(scoped_t('auth.invalid_email_or_confirmation_token'))
      end
    end

    context "with valid email and valid token" do
      it "responds with confirmed successfully" do
        user = create(:user)
        user.unconfirm!

        get :confirmation_instructions, user: { email: user.email }
        expect(response).to have_http_status(200)

        user.reload
        confirmation_token = user.confirmation_token
        request.headers['X-Access-Confirmation-Token'] = confirmation_token
        request.headers['X-Access-Email'] = user.email
        post :confirm
        expect(response).to have_http_status(200)
        expect(notice).to eq(scoped_t('auth.confirm_success'))

        user.reload
        expect(user.confirmation_token).to be_nil
        expect(user.confirmed_at).to be_present
        expect(user.confirmation_sent_at).to be_nil
        expect(location).to be_present
        expect(user.tokens).to eq({})
      end
    end
  end # confirm
end
