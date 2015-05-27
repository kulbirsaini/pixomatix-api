json.cache! image, expires_in: 12.hours do
  json.id image.uid
  json.caption image.caption
  json.vertical image.vertical?
  json.is_image image.image?
  json.is_gallery image.gallery?
  json.has_galleries image.has_galleries?
  json.has_images image.has_images?
  json.has_parent image.has_parent?
  json.parent_id image.parent.uid if image.has_parent?
  json.thumbnail_url get_absolute_url_for(image.thumbnail_path || image.get_random_image.try(:thumbnail_path) || asset_path('default_gallery_image_thumbnail.png'))
  json.hdtv_url get_absolute_url_for(image.hdtv_path || original_api_image_path(id: image.uid) || asset_path('default_gallery_image_hdtv.png')) if image.image?
  json.original_url get_absolute_url_for(original_api_image_path(id: image.uid)) if image.image?
  json.download_url get_absolute_url_for(download_api_image_path(id: image.uid)) if image.image?
end
