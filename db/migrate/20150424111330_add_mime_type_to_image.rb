class AddMimeTypeToImage < ActiveRecord::Migration
  def change
    add_column :images, :mime_type, :string
  end
end
