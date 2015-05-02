class AddHasGalleriesAndHasImagesToImages < ActiveRecord::Migration
  def change
    add_column :images, :has_galleries, :boolean, default: false
    add_column :images, :has_images, :boolean, default: false
  end
end
