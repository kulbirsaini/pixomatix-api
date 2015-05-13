class AddAwsUrlsFieldsToImage < ActiveRecord::Migration
  def change
    add_column :images, :aws_thumb_url, :string
    add_column :images, :aws_hdtv_url, :string
  end
end
