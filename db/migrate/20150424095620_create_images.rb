class CreateImages < ActiveRecord::Migration
  def change
    create_table :images do |t|
      t.integer :parent_id
      t.string :path
      t.string :filename
      t.integer :width
      t.integer :height
      t.integer :size
      t.string :mime_type
      t.boolean :has_galleries, default: false
      t.boolean :has_images, default: false

      t.timestamps null: false
    end
  end
end
