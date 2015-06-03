class Api::V1::UsersController < Api::V1::BaseController
  before_action :authenticate!

  def update
    if @current_user.update(update_params)
      @current_user.clear_tokens if update_params[:password].present?
      render_message({ user: @current_user.reload, notice: scoped_t('users.update_success') })
    else
      render_message({ error: @current_user.errors.full_messages, notice: scoped_t('users.update_failed'), status: :unprocessable_entity })
    end
  end

  def destroy
    @current_user.destroy
    if @current_user.destroyed?
      render_message({ notice: scoped_t('users.cancel_success') })
    else
      render_message({ error: @current_user.errors.full_messages, notice: scoped_t('users.cancel_failed'), status: :unprocessable_entity })
    end
  end

  private

  def update_params
    params[:user].present? ? params.require(:user).permit(:name, :password, :password_confirmation) : {}
  end
end
