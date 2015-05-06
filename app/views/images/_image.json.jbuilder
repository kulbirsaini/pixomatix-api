json.id image.id
json.caption image.caption
json.is_image image.image?
json.is_gallery image.gallery?
json.has_galleries image.has_galleries?
json.has_images image.has_images?
json.has_parent image.has_parent?
json.parent_id image.parent.id if image.has_parent?
json.thumbnail_path thumbnail_image_path(image)
json.hdtv_path hdtv_image_path(image) if image.image?
json.original_path original_image_path(image) if image.image?
