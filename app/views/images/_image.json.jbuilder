json.cache! image, expires_in: 12.hours do
  json.id image.id
  json.caption image.caption
  json.vertical image.vertical?
  json.is_image image.image?
  json.is_gallery image.gallery?
  json.has_galleries image.has_galleries?
  json.has_images image.has_images?
  json.has_parent image.has_parent?
  json.parent_id image.parent.id if image.has_parent?
  json.thumbnail_path image.thumbnail_path || image.get_random_image.try(:thumbnail_path) || asset_path('default_gallery_image_thumbnail.png')
  json.hdtv_path image.hdtv_path || original_image_path(image) || asset_path('default_gallery_image_hdtv.png') if image.image?
  json.original_path original_image_path(image) if image.image?
end
