module Pixomatix
  class ImageSync
    attr_accessor :directories

    def initialize(directories = nil)
      @directories = directories || Rails.application.config.x.image_root
    end

    def rename_images(directory = nil)
      if directory
        rename_images_from_directory_wrapper(directory)
        get_sub_directories(directory).each do |sub_directory|
          rename_images(sub_directory)
        end
      else
        @directories.each do |directory|
          rename_images_from_directory_wrapper(directory)
          get_sub_directories(directory).each do |sub_directory|
            rename_images(sub_directory)
          end
        end
      end
    end

    def get_datetime_from_exif(exif)
      exif['DateTimeOriginal'] || exif['DateTime']
    end

    def datetime_to_string(datetime)
      datetime.gsub(':', '').gsub(' ', '_')
    end

    def rename_images_from_directory_wrapper(directory)
      attempt = 0
      begin
        rename_images_from_directory(directory)
      rescue
        fix_exif_data(directory)
        rename_images_from_directory(directory)
      end
    end

    def rename_images_from_directory(directory)
      print "Renaming images from #{directory}..."
      images = Dir.entries(directory).sort.map do |filename|
        next if ['.', '..'].member?(filename)
        next if ['.mov', '.mpg', '.mpeg', '.dat', '.mp4', '.mp3', '.wmv', '.avi'].member?(File.extname(filename).downcase)
        filepath = File.join(directory, filename)
        image = nil
        begin
          image = MiniMagick::Image.open(filepath)
        rescue
        end
        if image
          data = [datetime_to_string(get_datetime_from_exif(image.exif)), filename]
          image.destroy!
          data
        else
          nil
        end
      end.compact.sort
      if images.select{ |image| image[1] !~ /KSC_[0-9]{8}_[0-9]{6}_/ }.count == 0
        puts 'not required!'
        return
      end
      length = images.count.to_s.size
      images.each_with_index.map do |image, index|
        old_filepath = File.join(directory, image[1])
        new_filepath = File.join(directory, Rails.application.config.x.image_prefix + '_' + image[0] + '_' + ("%0#{length}d" % (index + 1)) + File.extname(image[1]))
        File.rename(old_filepath, new_filepath)
      end
      puts 'done'
    rescue Exception => e
      puts 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX failed!'
      raise e
    end

    def self.generate_thumbnails
      Image.images.reverse.each do |image|
        filepath = image.thumbnail_path
        next if File.exists?(filepath)
        image.scale(Rails.application.config.x.thumbnail_width, Rails.application.config.x.thumbnail_height, filepath)
        p filepath
      end
      nil
    end

    def self.generate_hdtv_images
      Image.images.each do |image|
        filepath = image.hdtv_path
        next if File.exists?(filepath)
        image.resize(Rails.application.config.x.hdtv_width, Rails.application.config.x.hdtv_height, filepath)
        p filepath
      end
      nil
    end

    def populate_images(directory = nil, parent = nil)
      if directory
        parent = Image.where(path: directory, parent: parent).first_or_create
        popuplate_images_from_directory(directory, parent)
        directory = File.join(parent.directory_tree, directory) if parent
        get_sub_directories(directory).each do |sub_directory|
          populate_images(sub_directory, parent)
        end
      else
        @directories.each do |directory|
          parent = Image.where(path: directory).first_or_create
          popuplate_images_from_directory(directory, parent)
          get_sub_directories(directory).each do |sub_directory|
            populate_images(sub_directory, parent)
          end
        end
      end
    end

    def popuplate_images_from_directory(directory, parent)
      directory = File.join(parent.directory_tree, directory) if parent
      puts "Populating images from #{directory} ..."
      Dir.entries(directory).sort.map do |filename|
        next if ['.', '..'].member?(filename)
        next if ['.mov', '.mpg', '.mpeg', '.dat', '.mp4', '.mp3', '.wmv', '.avi'].member?(File.extname(filename).downcase)
        filepath = File.join(directory, filename)
        begin
          image = MiniMagick::Image.open(filepath)
          Image.where(filename: filename, width: image.width, height: image.height, size: image.size, parent: parent, mime_type: image.mime_type).first_or_create
          puts "Added #{filepath}"
          image.destroy!
        rescue ActiveRecord::ActiveRecordError => e
          puts e.message
        rescue Exception => e
        end
      end
      puts "Done with #{directory}!"
      nil
    end

    def get_sub_directories(directory)
      Dir.entries(directory).select{ |sub_dir| !['.', '..'].member?(sub_dir) && File.directory?(File.join(directory, sub_dir)) }.sort
    end

    def fix_exif_data(directory)
      timezone = Time.now.zone
      prev_filepath = nil
      Dir.entries(directory).sort.map do |filename|
        next if ['.', '..'].member?(filename)
        next if ['.mov', '.mpg', '.mpeg', '.dat', '.mp4', '.mp3', '.wmv', '.avi'].member?(File.extname(filename).downcase)
        filepath = File.join(directory, filename)
        begin
          image = MiniMagick::Image.open(filepath)
        rescue Exception => e
          next
        end
        prev_datatime = nil
        datetime = image.exif['DateTimeOriginal'] || image.exif['DateTime']
        unless datetime
          print "Fixing EXIF data for #{filename} ..."
          if prev_filepath
            prev_image = MiniMagick::Image.open(prev_filepath)
            prev_datatime = prev_image.exif['DateTimeOriginal'] || prev_image.exif['DateTime']
            prev_image.destroy!
          end
          if prev_datatime
            image_exif = MiniExiftool.new(filepath)
            datetime = (DateTime.strptime(prev_datatime + " #{timezone}", "%Y:%m:%d %H:%M:%S %Z").to_time + 1).to_s(:db) if prev_datatime
            image_exif[:date_time_original] = datetime
            image_exif.save
            puts "fixed!"
          else
            puts "failed!"
          end
        end
        image.destroy!
        prev_filepath = filepath
      end
      nil
    end

    def self.get_images_for_directory(directory)
      Dir.entries(directory).sort.map do |filename|
        next if ['.', '..'].member?(filename)
        next if ['.mov', '.mpg', '.mpeg', '.dat', '.mp4', '.mp3', '.wmv', '.avi'].member?(File.extname(filename).downcase)
        filepath = File.join(directory, filename)
        begin
          image = MiniMagick::Image.open(filepath)
          image.destroy!
          filename
        rescue
          nil
        end
      end.compact.sort
    end
  end
end
