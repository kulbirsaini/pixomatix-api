class AddUidToImages < ActiveRecord::Migration
  def change
    add_column :images, :uid, :string, null: false, unique: true
    add_index :images, :uid
  end
end
