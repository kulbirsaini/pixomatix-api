json.cache! image, expires_in: 12.hours do
  json.id image.uid
  json.caption image.caption
  json.vertical image.vertical?
  json.is_photo image.photo?
  json.is_gallery image.gallery?
  json.has_galleries image.has_galleries?
  json.has_photos image.has_photos?
  json.has_parent image.has_parent?
  json.parent_id image.parent.uid if image.has_parent?
  json.thumbnail_url get_absolute_url_for(image.thumbnail_path || image.get_random_photo.try(:thumbnail_path) || asset_path('default_gallery_image_thumbnail.png'))
  if image.photo?
    json.hdtv_url get_absolute_url_for(image.hdtv_path || original_api_gallery_path(id: image.uid) || asset_path('default_gallery_image_hdtv.png'))
    json.original_url get_absolute_url_for(original_api_gallery_path(id: image.uid))
    json.download_url get_absolute_url_for(download_api_gallery_path(id: image.uid))
  end
end
