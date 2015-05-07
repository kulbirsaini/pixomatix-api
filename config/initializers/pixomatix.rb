Rails.application.config_for(:pixomatix).each do |key, value|
  Rails.application.config.x.send(key + '=', value)
end

if Rails.application.config.x.image_cache_dir_in_rails_root
  Rails.application.config.x.image_cache_dir = File.join(Rails.root, Rails.application.config.x.image_cache_dir)
end
