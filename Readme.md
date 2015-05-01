Setup Instructions
1. Set image_root in config/pixomatix.yml
2. Run Pixomatix::ImageSync.new.populate_images
3. Run Pixomatix::ImageSync.generate_thumbnails
4. Run Pixomatix::ImageSync.generate_hdtv_images

API
/images.json => Array of galleries
Example : [{"id":1,"is_image":false,"is_gallery":true,"has_galleries":true,"has_images":true,"has_parent":false,"galleries_path":"/images/:id/galleries.json","images_path":"/images/:id/images.json","thumbnail_path":"/images/1/thumbnail"}]

/images/:id.json => Gallery Object
Example: {"id":1,"is_image":false,"is_gallery":true,"has_galleries":true,"has_images":true,"has_parent":false,"galleries_path":"/images/:id/galleries.json","images_path":"/images/:id/images.json","thumbnail_path":"/images/1/thumbnail"}

/images/:id/images.json => Array of images in a gallery
Example : [{"id":14142,"is_image":true,"is_gallery":false,"has_galleries":false,"has_images":false,"has_parent":true,"parent_gallery_path":"/images/:id.json","thumbnail_path":"/images/14142/thumbnail","hdtv_path":"/images/14142/hdtv","original_path":"/images/14142/original"}, ...]

/images/:id/galleries.json => Array of galleries in a gallery
Example: [{"id":2,"is_image":false,"is_gallery":true,"has_galleries":false,"has_images":true,"has_parent":true,"parent_gallery_path":"/images/:id.json","images_path":"/images/:id/images.json","thumbnail_path":"/images/2/thumbnail"}, ...]
