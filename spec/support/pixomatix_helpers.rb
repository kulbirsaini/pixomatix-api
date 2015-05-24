module PixomatixHelpers
  def json
    JSON.parse(response.body || {})
  end

  def notice
    json['notice']
  end

  def location
    json['location']
  end

  def scoped_t(string, options = {})
    I18n.t("api.v1.#{string}", options)
  end
end

RSpec.configure do |config|
  config.include PixomatixHelpers
end
