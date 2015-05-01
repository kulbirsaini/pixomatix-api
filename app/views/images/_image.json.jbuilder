json.id image.id
json.is_image image.image?
json.is_gallery image.gallery?
json.has_galleries image.has_galleries?
json.has_images image.has_images?
json.has_parent image.has_parent?
#json.parent_gallery_path image_path(image.parent, format: :json) if image.has_parent?
#json.images_path images_image_path(image, format: :json) if image.has_images?
#json.galleries_path galleries_image_path(image, format: :json) if image.has_galleries?
json.parent_gallery_path "/images/:id.json" if image.has_parent?
json.galleries_path "/images/:id/galleries.json" if image.has_galleries?
json.images_path "/images/:id/images.json" if image.has_images?
json.thumbnail_path thumbnail_image_path(image)
json.hdtv_path hdtv_image_path(image) if image.image?
json.original_path original_image_path(image) if image.image?
