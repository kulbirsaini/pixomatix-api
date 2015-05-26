class Api::V1::UsersMailer < Api::V1::BaseMailer

  def registration_confirmation(user)
    @user = user
    mail to: "#{@user.name} <#{@user.email}>", subject: 'Welcome to Pixomatix!'
    @user.update confirmation_sent_at: Time.now
  end

  def confirmation_token(user)
    @user = user
    mail to: "#{@user.name} <#{@user.email}>", subject: 'Your Pixomatix confirmation token!'
    @user.update confirmation_sent_at: Time.now
  end

  def reset_password_token(user)
    @user = user
    mail to: "#{@user.name} <#{@user.email}>", subject: 'Your Pixomatix reset password token!'
    @user.update reset_password_token_sent_at: Time.now
  end

  def unlock_token(user)
    @user = user
    mail to: "#{@user.name} <#{@user.email}>", subject: 'Your Pixomatix account unlock token!'
  end
end
