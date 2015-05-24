class User < ActiveRecord::Base
  attr_accessor :password

  serialize :tokens

  TOKEN_LIFE = 2.weeks

  before_save :encrypt_password
  before_save :drop_expired_token
  before_create :set_confirmation_token

  after_initialize :set_tokens
  after_save :clear_password
  after_destroy :clear_password

  validates :name, presence: true
  validates :email, presence: true, uniqueness: true, format: { with: /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i }

  # Only on create
  validates :password, presence: true, confirmation: true, length: { in: 6..31 }, on: :create
  validates :password_confirmation, presence: true, on: :create

  # Only on update
  validates :password, confirmation: true, allow_nil: true, length: { in: 6..31 }, on: :update
  validates :password_confirmation, presence: true, if: "password.present?", on: :update

  def as_json(options = {})
    { name: name, email: email }
  end

  def self.generate_token
    SecureRandom.hex(16)
  end

  def confirm!
    update confirmed_at: Time.now, confirmation_token: nil, confirmation_sent_at: nil
  end

  def unconfirm!
    update confirmed_at: nil, confirmation_token: nil, confirmation_sent_at: nil
  end

  def confirmed?
    confirmed_at.present?
  end

  def valid_confirmation_token?(token)
    token.present? && self.confirmation_token == token
  end

  def set_confirmation_token!
    self.confirmation_token = self.class.generate_token
    save
  end

  def lock!
    update locked_at: Time.now, unlock_token: nil, tokens: {}
  end

  def unlock!
    update locked_at: nil, unlock_token: nil, failed_attempts: 0
  end

  def locked?
    locked_at.present?
  end

  def valid_unlock_token(token)
    token.present? && self.unlock_token == token
  end

  def set_unlock_token!
    self.unlock_token = self.class.generate_token
    save
  end

  def valid_reset_password_token?(token)
    token.present? && self.reset_password_token == token
  end

  def set_reset_passwork_token!
    self.reset_password_token = self.class.generate_token
    save
  end

  def valid_auth_token?(token)
    token.present? && self.tokens.keys.member?(token) && self.tokens[token][:expires_at] > Time.now.to_i
  end

  def issue_token
    token = self.class.generate_token
    self.tokens[token] = { expires_at: TOKEN_LIFE.from_now.to_i }
    save
    token
  end

  def destroy_token(token)
    self.tokens.delete(token)
    save
  end

  def clear_tokens
    update tokens: {}
  end

  def valid_password?(password)
    password && encrypted_password == BCrypt::Engine.hash_secret(password, password_salt)
  end

  def clear_password
    self.password = self.password_confirmation = nil
  end

  def self.authenticate(email, password)
    user = User.where(email: email).first
    user && user.encrypted_password == BCrypt::Engine.hash_secret(password, user.password_salt) ? user : nil
  end

  private

  def set_confirmation_token
    self.confirmation_token = self.class.generate_token
  end

  def set_tokens
    self.tokens ||= {}
  end

  def drop_expired_token
    self.tokens.keys.each do |token|
      self.tokens.delete(token) if self.tokens[token][:expires_at] < Time.now.to_i
    end
  end

  def encrypt_password
    return unless password.present? && password_confirmation.present?
    self.password_salt = BCrypt::Engine.generate_salt
    self.encrypted_password = BCrypt::Engine.hash_secret(password, password_salt)
  end
end
