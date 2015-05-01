module ImagesHelper
  def get_asset_path(filename)
    File.join(Rails.root, 'app/assets/images', filename)
  end
end
