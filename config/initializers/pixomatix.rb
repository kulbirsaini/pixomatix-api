Rails.application.config_for(:pixomatix).each do |key, value|
  Rails.application.config.x.send(key + '=', value)
end

Rails.application.config.x.image_cache_path_prefix = Rails.application.config.x.image_cache_dir.gsub(/public\//, '')
Rails.application.config.x.image_cache_dir = File.join(Rails.root, Rails.application.config.x.image_cache_dir)
