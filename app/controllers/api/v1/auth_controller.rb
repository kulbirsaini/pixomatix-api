class Api::V1::AuthController < Api::V1::BaseController
  before_action :authenticate!, except: [ :register, :login, :validate, :reset_password_instructions, :reset_password, :unlock_instructions, :unlock, :confirmation_instructions, :confirm ]
  before_action :set_user, only: [ :register, :login, :reset_password_instructions, :unlock_instructions, :confirmation_instructions ]
  before_action :set_user_from_request, only: [ :reset_password, :unlock, :confirm ]

  def register
    if @user
      if !@user.confirmed?
        render_message({ notice: scoped_t('auth.registered_and_unconfirmed'), status: :unauthorized })
      else
        render_message({ notice: scoped_t('auth.registered_already'), location: login_api_auth_index_path, status: :unauthorized })
      end
    else
      @user = User.create(user_params)
      if @user.valid?
        render_message({ user: @user, notice: scoped_t('auth.registered_successfully') })
      else
        render_message({ error: @user.errors.full_messages, notice: scoped_t('auth.registration_failed'), status: :unprocessable_entity })
      end
    end
  end

  def login
    if @user
      if @user.locked?
        render_message({ notice: scoped_t('auth.user_locked'), location: unlock_api_auth_index_path, status: :unauthorized })
      elsif !@user.confirmed?
        render_message({ notice: scoped_t('auth.user_not_confirmed'), location: login_api_auth_index_path, status: :unauthorized })
      elsif @user.valid_password?(user_params[:password])
        render_message({ user: @user, token: @user.issue_token, notice: scoped_t('auth.login_success') })
      else
        render_message({ notice: scoped_t('auth.invalid_credentials'), status: :unauthorized })
      end
    else
      render_message({ notice: scoped_t('auth.invalid_credentials'), status: :unauthorized })
    end
  end

  def user
    render_message({ user: @current_user })
  end

  def logout
    if @current_user.destroy_token(@current_token)
      render_message({ notice: scoped_t('auth.logout_success'), location: login_api_auth_index_path })
    else
      render_message({ notice: scoped_t('auth.logout_failed'), status: :unprocessable_entity })
    end
  end

  def validate
    authenticate!(halt: false)
    if @current_user
      render_message({ user: current_user, notice: scoped_t('auth.token_valid') })
    else
      render_message({ notice: scoped_t('auth.token_invalid'), status: :unauthorized })
    end
  end

  def reset_password_instructions
    if @user && @user.set_reset_passwork_token!
      #TODO send email
      render_message({ notice: scoped_t('auth.reset_password_sent'), location: login_api_auth_index_path })
    else
      render_message({ notice: scoped_t('auth.cannot_reset_password'), status: :unprocessable_entity })
    end
  end

  def reset_password
    if @user && @user.valid_reset_password_token?(request.headers['X-Access-Reset-Password-Token'])
      if reset_password_params[:password].present? && @user.update(reset_password_params.merge(reset_password_token: nil, reset_password_token_sent_at: nil))
        @user.clear_tokens
        render_message({ notice: scoped_t('auth.password_reset_success'), location: login_api_auth_index_path })
      else
        render_message({ notice: scoped_t('auth.password_reset_failed'), error: @user.errors.full_messages, status: :unprocessable_entity })
      end
    else
      render_message({ notice: scoped_t('auth.invalid_email_or_password_token'), status: :unauthorized })
    end
  end

  def unlock_instructions
    if @user && @user.locked? && @user.set_unlock_token!
      #TODO send email
      render_message({ notice: scoped_t('auth.unlock_sent'), location: login_api_auth_index_path })
    else
      render_message({ notice: scoped_t('auth.cannot_unlock'), status: :unprocessable_entity })
    end
  end

  def unlock
    if @user && @user.valid_unlock_token(request.headers['X-Access-Unlock-Token'])
      if @user.unlock!
        @user.clear_tokens
        render_message({ notice: scoped_t('auth.unlock_success'), location: login_api_auth_index_path })
      else
        render_message({ notice: scoped_t('auth.unlock_failed'), status: :unprocessable_entity })
      end
    else
      render_message({ notice: scoped_t('auth.invalid_email_or_unlock_token'), status: :unauthorized })
    end
  end

  def confirmation_instructions
    if @user && !@user.confirmed? && @user.set_confirmation_token!
      #TODO send email
      render_message({ notice: scoped_t('auth.confirmation_sent'), location: login_api_auth_index_path })
    else
      render_message({ notice: scoped_t('auth.cannot_confirm'), status: :unprocessable_entity })
    end
  end

  def confirm
    if @user && @user.valid_confirmation_token?(request.headers['X-Access-Confirmation-Token'])
      if @user.confirm!
        @user.clear_tokens
        render_message({ notice: scoped_t('auth.confirm_success'), location: login_api_auth_index_path })
      else
        render_message({ notice: scoped_t('auth.confirm_failed'), status: :unprocessable_entity })
      end
    else
      render_message({ notice: scoped_t('auth.invalid_email_or_confirmation_token'), status: :unauthorized })
    end
  end

  private

  def set_user_from_request
    @user = User.where(email: request.headers['X-Access-Email']).first
  end

  def set_user
    @user = User.where(email: user_params[:email]).first
  end

  def reset_password_params
    params[:user].present? ? params.require(:user).permit(:password, :password_confirmation) : {}
  end

  def user_params
    params[:user].present? ? params.require(:user).permit(:name, :email, :password, :password_confirmation) : {}
  end
end
