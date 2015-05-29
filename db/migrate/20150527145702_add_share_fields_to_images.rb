class AddShareFieldsToImages < ActiveRecord::Migration
  def change
    add_column :images, :user_id, :integer
    add_column :images, :share_token, :string
    add_column :images, :share_token_expires_at, :string
    add_column :images, :share_token_password, :string
    add_column :images, :public, :boolean, null: false, default: false

    add_index :images, :share_token
    add_index :images, :share_token_expires_at
    add_index :images, :share_token_password
  end
end
