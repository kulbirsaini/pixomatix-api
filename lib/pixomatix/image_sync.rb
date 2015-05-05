module Pixomatix
  class ImageSync
    attr_reader :directories

    def initialize(directories = nil)
      directories = directories.present? ? [ directories ].flatten : nil
      @directories = directories || Rails.application.config.x.image_root
    end

    def self.generate_thumbnails(images = nil)
      (images || Image.images).each do |image|
        filepath = image.thumbnail_path
        next if File.exists?(filepath)
        result = image.scale(Rails.application.config.x.thumbnail_width, Rails.application.config.x.thumbnail_height, filepath)
        puts "Generated thumbnail for #{image.original_path} at #{filepath}" if result
      end
      nil
    end

    def self.generate_hdtv_images(images = nil)
      (images || Image.images).each do |image|
        filepath = image.hdtv_path
        next if File.exists?(filepath)
        result = image.resize_to_hdtv(Rails.application.config.x.hdtv_height, filepath)
        puts "Generated HDTV image for #{image.original_path} at #{filepath}" if result
      end
      nil
    end

    def rename_images(directory = nil)
      if directory
        rename_images_from_directory_wrapper(directory)
        self.class.get_sub_directories(directory).each do |sub_directory|
          rename_images(File.join(directory, sub_directory))
        end
      else
        @directories.each do |directory|
          rename_images_from_directory_wrapper(directory)
          self.class.get_sub_directories(directory).each do |sub_directory|
            rename_images(File.join(directory, sub_directory))
          end
        end
      end
    end

    def fix_exif_data(directory)
      timezone = Time.now.zone
      prev_datatime = nil

      Dir.entries(directory).sort.map do |filename|
        next unless self.class.is_image_extension?(filename)
        filepath = File.join(directory, filename)
        image = MiniMagick::Image.open(filepath)
        datetime = image.exif['DateTimeOriginal'] || image.exif['DateTime']
        image.destroy!

        if datetime.nil? && prev_datatime.nil?
          puts 'failed! Halting...!!'
          return
        elsif datetime.nil?
          print "Fixing EXIF data for #{filename} ..."
          image_exif = MiniExiftool.new(filepath)
          datetime = (DateTime.strptime(prev_datatime + " #{timezone}", "%Y:%m:%d %H:%M:%S %Z").to_time + 1).to_s(:db)
          image_exif[:date_time_original] = datetime
          image_exif.save
          puts "fixed!"
        end
        prev_datatime = datetime
      end
      nil
    end

    def rename_images_from_directory_wrapper(directory)
      begin
        rename_images_from_directory(directory)
      rescue
        fix_exif_data(directory)
        rename_images_from_directory(directory)
      end
    end

    def rename_images_from_directory(directory)
      print "Renaming images from #{directory}..."
      image_name_regex = /#{Rails.application.config.x.image_prefix}_[0-9]{8}_[0-9]{6}_/
      images = Dir.entries(directory).map do |filename|
        next unless self.class.is_image_extension?(filename)
        filepath = File.join(directory, filename)
        image = MiniMagick::Image.open(filepath)
        data = [(image.exif['DateTimeOriginal'] || image.exif['DateTime']).gsub(':', '').gsub(' ', '_'), filename, filepath]
        image.destroy!
        data
      end.compact.sort

      if images.select{ |image| image[1] !~ image_name_regex }.count == 0
        puts 'not required!'
        return
      end

      length = images.count.to_s.size
      images.each_with_index.map do |image, index|
        new_filepath = File.join(directory, Rails.application.config.x.image_prefix + '_' + image[0] + '_' + ("%0#{length}d" % (index + 1)) + File.extname(image[1]))
        File.rename(image[2], new_filepath)
      end
      puts 'done'
    rescue Exception => e
      puts 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX failed!'
      raise e
    end

    def populate_images(directory = nil, parent = nil)
      if directory
        parent = Image.find_or_create_by(path: directory, parent: parent)
        popuplate_images_from_directory(directory, parent)
        directory = File.join(parent.directory_tree, directory) if parent
        self.class.get_sub_directories(directory).each do |sub_directory|
          populate_images(sub_directory, parent)
        end
      else
        @directories.each do |directory|
          parent = Image.find_or_create_by(path: directory)
          popuplate_images_from_directory(directory, parent)
          self.class.get_sub_directories(directory).each do |sub_directory|
            populate_images(sub_directory, parent)
          end
        end
      end
    end

    def popuplate_images_from_directory(directory, parent, force_populate = false)
      directory = File.join(parent.directory_tree, directory) if parent
      puts "Populating images from #{directory} ..."
      images_in_dir = Dir.entries(directory)
      images_in_db = force_populate ? [] : Image.where(parent: parent).where.not(filename: nil).select(:filename).collect(&:filename)
      images_to_create = (images_in_dir - images_in_db).select{ |filename| self.class.is_image_extension?(filename) }.sort
      images_to_delete = images_in_db - images_in_dir
      Image.where(filename: images_to_delete, parent: parent).destroy_all

      images_to_create.each do |filename|
        image = MiniMagick::Image.open(File.join(directory, filename))
        Image.find_or_create_by(filename: filename, width: image.width, height: image.height, size: image.size, parent: parent, mime_type: image.mime_type)
        puts "Added #{filename} from #{directory}"
        image.destroy!
      end
      puts "Done with #{directory}! Created: #{images_to_create.count}, Deleted: #{images_to_delete.count}"
    end

    def self.is_image_extension?(filename)
      ['.jpg', '.jpeg', '.png', '.bmp', '.gif'].member?(File.extname(filename).downcase)
    end

    def self.get_sub_directories(directory)
      Dir.entries(directory).select{ |sub_dir| !['.', '..'].member?(sub_dir) && File.directory?(File.join(directory, sub_dir)) }.sort
    end

    def self.get_images_for_directory(directory)
      Dir.entries(directory).map do |filename|
        next unless is_image_extension?(filename)
        image = MiniMagick::Image.open(File.join(directory, filename))
        image.destroy!
        filename
      end.compact.sort
    end
  end
end
