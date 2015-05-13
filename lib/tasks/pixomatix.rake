namespace :pixomatix do
  desc "Populate images once the image root directory is setup in config/pixomatix.yml"
  task populate_images: :environment do
    Pixomatix::ImageSync.new.populate_images(nil, nil, false, true)
  end

  desc "Remove existing entries from database and populate images again"
  task repopulate_images: :environment do
    Pixomatix::ImageSync.new.populate_images(nil, nil, true, true)
  end

  desc "Run frequently (daily or so) to remove unused thumbnails and hdtv images"
  task optimize_cache: :environment do
    Pixomatix::ImageSync.optimize_cache(true)
  end

  desc "Rename images (EXIF date/time ascending) as per the filename template defined in config/pixomatix.yml"
  task rename_images: :environment do
    Pixomatix::ImageSync.new.rename_images(nil, true)
  end

  desc "Generate thumbnails as per the dimensions mentioned in config/pixomatix.yml"
  task generate_thumbnails: :environment do
    Pixomatix::ImageSync.generate_thumbnails(nil, true)
  end

  desc "Generate hdtv images as per the dimensions mentioned in config/pixomatix.yml"
  task generate_hdtv_images: :environment do
    Pixomatix::ImageSync.generate_hdtv_images(nil, true)
  end

  desc "Sync thumbnails to AWS S3"
  task sync_thumbnails: :environment do
    Pixomatix::AwsSync.sync_thumbnails(nil, true)
  end

  desc "Sync HDTV images to AWS S3"
  task sync_hdtv_images: :environment do
    Pixomatix::AwsSync.sync_hdtv_images(nil, true)
  end

  desc "Sync thumbnails and HDTV images to AWS S3"
  task aws_sync: :environment do
    Rake::Task["pixomatix:sync_thumbnails"].invoke
    Rake::Task["pixomatix:sync_hdtv_images"].invoke
  end
end
