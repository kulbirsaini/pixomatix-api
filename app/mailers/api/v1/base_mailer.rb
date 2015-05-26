class Api::V1::BaseMailer < ActionMailer::Base
  default from: "Kulbir Saini <saini@saini.co.in>"
  layout 'mailer'
end
