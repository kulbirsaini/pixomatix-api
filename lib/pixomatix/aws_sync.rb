module Pixomatix
  class AwsSync
    extend Pixomatix::Common

    def self.get_image_ids_from_bucket(bucket, type)
      regex = type == :thumbnail ? Rails.application.config.x.thumbnail_path_regex : Rails.application.config.x.hdtv_path_regex
      bucket.objects.map{ |i| i.key.split('/')[-1] }.select{ |i| i =~ regex }.map{ |i| i.split('_')[0] }
    end

    def self.sync_thumbnails(images = nil, msg_to_stdout = false)
      if !Rails.application.config.x.use_aws
        self.info("AwsSync::sync_thumbnails AWS S3 storage not enabled. Check config/pixomatix.yml", msg_to_stdout)
        return
      end
      self.info("AwsSync::sync_thumbnails Start", msg_to_stdout)
      bucket = Aws::S3::Resource.new.bucket(Rails.application.config.x.s3_bucket)
      (images || Image.images).where.not(uid: get_image_ids_from_bucket(bucket, :thumbnail)).each do |image|
        filepath = image.absolute_thumbnail_path
        aws_key = image.thumbnail_path
        if File.exists?(filepath)
          object = bucket.object(aws_key)
          object.upload_file(filepath, acl: 'public-read')
          image.update(aws_thumb_url: object.public_url)
          self.info("AwsSync::sync_thumbnails Synced thumbnail #{filepath} for Image: #{image.id}", msg_to_stdout)
        else
          self.info("AwsSync::sync_thumbnails Thumbnail not found for Image: #{image.id}", msg_to_stdout)
        end
      end
      self.info("AwsSync::sync_thumbnails Finish", msg_to_stdout)
      nil
    end

    def self.sync_hdtv_images(images = nil, msg_to_stdout = false)
      if !Rails.application.config.x.use_aws
        self.info("AwsSync::sync_hdtv_images AWS S3 storage not enabled. Check config/pixomatix.yml", msg_to_stdout)
        return
      end
      self.info("AwsSync::sync_hdtv_images Start", msg_to_stdout)
      public_dir = File.join(Rails.root, 'public/')
      bucket = Aws::S3::Resource.new.bucket(Rails.application.config.x.s3_bucket)
      (images || Image.images).where.not(uid: get_image_ids_from_bucket(bucket, :hdtv)).each do |image|
        filepath = image.absolute_hdtv_path
        filepath = image.original_path unless File.exists?(filepath)
        aws_key = image.hdtv_path || image.absolute_hdtv_path.gsub(public_dir, '')
        if File.exists?(filepath)
          object = bucket.object(aws_key)
          object.upload_file(filepath, acl: 'public-read')
          image.update(aws_hdtv_url: object.public_url)
          self.info("AwsSync::sync_hdtv_images Synced HDTV image #{filepath} for Image: #{image.id}", msg_to_stdout)
        else
          self.info("AwsSync::sync_hdtv_images HDTV image not found for Image: #{image.id}", msg_to_stdout)
        end
      end
      nil
    end
  end
end
