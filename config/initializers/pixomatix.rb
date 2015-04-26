Rails.application.config_for(:pixomatix).each do |key, value|
  Rails.application.config.x.send(key + '=', value)
end
