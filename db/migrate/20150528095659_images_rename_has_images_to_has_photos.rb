class ImagesRenameHasImagesToHasPhotos < ActiveRecord::Migration
  def change
    rename_column :images, :has_images, :has_photos
  end
end
