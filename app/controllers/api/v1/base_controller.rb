class Api::V1::BaseController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :null_session, :if => Proc.new { |c| c.request.format == 'application/vnd.pixomatix.v1' }
  before_action :set_cors_request_header
  before_action :set_locale
  before_action :set_current_token
  before_action :authenticate!

  around_filter :generic_exception

  private

  def scoped_t(string, options = {})
    I18n.t("api.v1.#{string}", options)
  end

  def render_message(message)
    status = message.delete(:status) || :ok
    render json: message, status: status
  end

  def generic_exception
    begin
      yield
    rescue Exception => e
      Rails.logger.debug ([e.message] + e.backtrace.first(25)).join("\n")
      render_message({ error: e.message, notice: scoped_t('base.internal_server_error'), status: :internal_server_error })
    end
  end

  def set_locale
    I18n.locale = params[:locale] || I18n.default_locale
  end

  def set_cors_request_header
    response.headers['Access-Control-Allow-Origin'] = '*'
  end

  def authenticate!(options = { halt: true })
    user = User.where(email: request.headers['X-Access-Email']).first
    @current_user = user if user && user.valid_auth_token?(@current_token)
    render_message({ notice: scoped_t('base.invalid_session'), location: login_api_auth_index_path, status: :unauthorized }) if !@current_user && options[:halt]
  end

  def set_current_token
    @current_token = request.headers['X-Access-Token']
  end

  def current_user
    @current_user
  end

  def current_token
    @current_token
  end
end
