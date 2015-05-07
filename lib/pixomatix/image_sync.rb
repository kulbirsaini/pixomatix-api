module Pixomatix
  class ImageSync
    attr_reader :directories

    def initialize(directories = nil)
      directories = directories.present? ? [ directories ].flatten : nil
      @directories = directories || Rails.application.config.x.image_root
    end

    def self.parse_filename(filename)
      result = filename.scan(Rails.application.config.x.thumbnail_path_regex)[0]
      if result.present?
        return { type: :thumbnail, id: result[0], width: result[1], height: result[2] }
      end
      result = filename.scan(Rails.application.config.x.hdtv_path_regex)[0]
      if result.present?
        return { type: :hdtv, id: result[0], hdtv_height: result[1] }
      end
    end

    def self.info(message, msg_to_stdout = false)
      Rails.logger.info message
      puts message if msg_to_stdout
    end

    def self.debug(message, msg_to_stdout = false)
      Rails.logger.debug message
      puts message if msg_to_stdout
    end

    def self.optimize_cache(msg_to_stdout = false)
      image_cache_dir = Rails.application.config.x.image_cache_dir
      self.info("Pixomatix::optimize_cache Start optimize_cache image_cache_dir: #{image_cache_dir}", msg_to_stdout)
      self.get_sub_directories(image_cache_dir).each do |sub_directory|
        directory = File.join(image_cache_dir, sub_directory)
        self.info("Pixomatix::optimize_cache Optimizing cache for #{directory}", msg_to_stdout)
        Dir.entries(directory).each do |filename|
          next unless self.is_image_extension?(filename)
          filepath = File.join(directory, filename)
          keep_file = false
          if result = self.parse_filename(filename)
            if image = Image.where(id: result[:id]).first
              keep_file = true if image.send(result[:type].to_s + '_path') == filepath
            end
          end
          unless keep_file
            FileUtils.rm(filepath)
            self.info("Pixomatix::optimize_cache Removed file #{filepath}", msg_to_stdout)
          end
        end
        if Dir.entries(directory).size == 2
          FileUtils.rmdir(directory)
          self.info("Pixomatix::optimize_cache Removed directory #{directory}", msg_to_stdout)
        end
      end
      self.info("Pixomatix::optimize_cache Finish optimize_cache image_cache_dir: #{image_cache_dir}", msg_to_stdout)
      nil
    end

    def self.generate_thumbnails(images = nil, msg_to_stdout = false)
      self.info("Pixomatix::generate_thumbnails Start", msg_to_stdout)
      (images || Image.images).each do |image|
        filepath = image.thumbnail_path
        if File.exists?(filepath)
          self.info("Pixomatix::generate_thumbnails Exists at #{filepath} for Image: #{image.id}", msg_to_stdout)
          next
        end
        if image.scale(Rails.application.config.x.thumbnail_width, Rails.application.config.x.thumbnail_height, filepath)
          self.info("Pixomatix::generate_thumbnails Created at #{filepath} for Image: #{image.id}", msg_to_stdout)
        else
          self.info("Pixomatix::generate_thumbnails Not required for Image: #{image.id}", msg_to_stdout)
        end
      end
      self.info("Pixomatix::generate_thumbnails Finish", msg_to_stdout)
      nil
    end

    def self.generate_hdtv_images(images = nil, msg_to_stdout = false)
      self.info("Pixomatix::generate_hdtv_images Start", msg_to_stdout)
      (images || Image.images).each do |image|
        filepath = image.hdtv_path
        if File.exists?(filepath)
          self.info("Pixomatix::generate_hdtv_images Exists at #{filepath} for Image: #{image.id}", msg_to_stdout)
          next
        end
        if image.resize_to_hdtv(Rails.application.config.x.hdtv_height, filepath)
          self.info("Pixomatix::generate_hdtv_images Created at #{filepath} for Image: #{image.id}", msg_to_stdout)
        else
          self.info("Pixomatix::generate_hdtv_images Not required for Image: #{image.id}", msg_to_stdout)
        end
      end
      self.info("Pixomatix::generate_hdtv_images Finish", msg_to_stdout)
      nil
    end

    def rename_images(directory = nil, msg_to_stdout = false)
      if directory
        rename_images_from_directory_wrapper(directory, msg_to_stdout)
        self.class.get_sub_directories(directory).each do |sub_directory|
          rename_images(File.join(directory, sub_directory), msg_to_stdout)
        end
      else
        @directories.each do |directory|
          rename_images_from_directory_wrapper(directory, msg_to_stdout)
          self.class.get_sub_directories(directory).each do |sub_directory|
            rename_images(File.join(directory, sub_directory), msg_to_stdout)
          end
        end
      end
    end

    def fix_exif_data(directory, msg_to_stdout = false)
      self.class.info("Pixomatix::fix_exif_data Start for #{directory}", msg_to_stdout)
      timezone = Time.now.zone
      prev_datatime = nil

      Dir.entries(directory).sort.map do |filename|
        next unless self.class.is_image_extension?(filename)
        filepath = File.join(directory, filename)
        image = MiniMagick::Image.open(filepath)
        datetime = image.exif['DateTimeOriginal'] || image.exif['DateTime']
        image.destroy!

        if datetime.nil? && prev_datatime.nil?
          self.class.info("Pixomatix::fix_exif_data Failed. Not enough data. Halting...!", msg_to_stdout)
          return
        elsif datetime.nil?
          self.class.info("Pixomatix::fix_exif_data Fixing EXIF data for #{filepath}", msg_to_stdout)
          image_exif = MiniExiftool.new(filepath)
          datetime = (DateTime.strptime(prev_datatime + " #{timezone}", "%Y:%m:%d %H:%M:%S %Z").to_time + 1).to_s(:db)
          image_exif[:date_time_original] = datetime
          image_exif.save
        end
        prev_datatime = datetime
      end
      true
    rescue Exception => e
      self.class.info("Pixomatix::fix_exif_data Error for #{directory}", msg_to_stdout)
      self.class.debug("Pixomatix::fix_exif_data Trace\n#{e.backtrace.join("\n")}", msg_to_stdout)
      raise e
    ensure
      self.class.info("Pixomatix::fix_exif_data Finish for #{directory}", msg_to_stdout)
    end

    def rename_images_from_directory_wrapper(directory, msg_to_stdout = false)
      begin
        rename_images_from_directory(directory, msg_to_stdout)
      rescue
        rename_images_from_directory(directory, msg_to_stdout) if fix_exif_data(directory, msg_to_stdout)
      end
    end

    def rename_images_from_directory(directory, msg_to_stdout = false)
      self.class.info("Pixomatix::rename_images_from_directory Start #{directory}", msg_to_stdout)
      images = Dir.entries(directory).map do |filename|
        next unless self.class.is_image_extension?(filename)
        filepath = File.join(directory, filename)
        image = MiniMagick::Image.open(filepath)
        data = { datetime: (image.exif['DateTimeOriginal'] || image.exif['DateTime']).gsub(':', '').gsub(' ', '_'), filename: filename, filepath: filepath }
        image.destroy!
        data
      end.compact.sort_by{ |data| data[:datetime] }
      length = images.count.to_s.size
      images = images.each_with_index.map do |image, index|
        new_filename = Rails.application.config.x.image_prefix + '_' + image[:datetime] + '_' + ("%0#{length}d" % (index + 1)) + File.extname(image[:filename])
        image.merge!({ new_filename: new_filename, new_filepath: File.join(directory, new_filename) })
      end

      if images.select{ |image| image[:new_filename] != image[:filename] }.count == 0
        self.class.info("Pixomatix::rename_images_from_directory Not required", msg_to_stdout)
        return
      end

      tmp_dir = "tmp/#{SecureRandom.hex(10)}-removable"
      tmp_dir_path = File.join(Rails.application.config.x.image_cache_dir, tmp_dir)
      FileUtils.mkdir_p(tmp_dir_path)
      self.class.info("Pixomatix::rename_images_from_directory Created tmp directory #{tmp_dir_path}", msg_to_stdout)
      images.each do |image|
        image[:tmp_filepath] = File.join(tmp_dir_path, image[:filename])
        FileUtils.mv(image[:filepath], image[:tmp_filepath])
        self.class.info("Pixomatix::rename_images_from_directory #{image[:filepath]} => #{image[:tmp_filepath]}", msg_to_stdout)
      end
      images.each do |image|
        FileUtils.mv(image[:tmp_filepath], image[:new_filepath])
        self.class.info("Pixomatix::rename_images_from_directory #{image[:tmp_filepath]} => #{image[:new_filepath]}", msg_to_stdout)
      end
      FileUtils.rmdir(tmp_dir_path)
      self.class.info("Pixomatix::rename_images_from_directory Removed tmp directory #{tmp_dir_path}", msg_to_stdout)
    rescue Exception => e
      self.class.info("Pixomatix::rename_images_from_directory Error for #{directory}", msg_to_stdout)
      self.class.debug("Pixomatix::rename_images_from_directory Trace\n#{e.backtrace.join("\n")}", msg_to_stdout)
      raise e
    ensure
      self.class.info("Pixomatix::rename_images_from_directory Finish #{directory}", msg_to_stdout)
    end

    def populate_images(directory = nil, parent = nil, force_populate = false, msg_to_stdout = false)
      self.class.info("Pixomatix::populate_images Start", msg_to_stdout) unless parent
      if directory
        parent = Image.where(path: directory, parent: parent).first_or_initialize
        parent.save
        populate_images_from_directory(directory, parent, force_populate, msg_to_stdout)
        directory = File.join(parent.directory_tree, directory) if parent
        self.class.get_sub_directories(directory).each do |sub_directory|
          populate_images(sub_directory, parent, force_populate, msg_to_stdout)
        end
        if parent.children.count == 0 && parent.images.count == 0
          self.class.info("Pixomatix::populate_images Removed parent : #{parent.id}", msg_to_stdout)
          parent.destroy
        end
      else
        @directories.each do |directory|
          parent = Image.where(path: directory).first_or_initialize
          parent.save
          populate_images_from_directory(directory, parent, force_populate, msg_to_stdout)
          self.class.get_sub_directories(directory).each do |sub_directory|
            populate_images(sub_directory, parent, force_populate, msg_to_stdout)
          end
          if parent.children.count == 0 && parent.images.count == 0
            self.class.info("Pixomatix::populate_images Removed parent : #{parent.id}", msg_to_stdout)
            parent.destroy
          end
        end
      end
      self.class.info("Pixomatix::populate_images Finish", msg_to_stdout) unless parent.parent
    end

    def populate_images_from_directory(directory, parent, force_populate = false, msg_to_stdout = false)
      directory = File.join(parent.directory_tree, directory) if parent
      self.class.info("Pixomatix::populate_images_from_directory Start for #{directory}", msg_to_stdout)
      images_in_dir = Dir.entries(directory).select{ |filename| self.class.is_image_extension?(filename) }.sort
      if force_populate
        images_to_create = images_in_dir
        images_to_delete = Image.where(parent: parent).where.not(filename: nil).select(:filename).collect(&:filename)
      else
        images_in_db = Image.where(parent: parent).where.not(filename: nil).select(:filename).collect(&:filename)
        images_to_create = images_in_dir - images_in_db
        images_to_delete = images_in_db - images_in_dir
      end
      Image.where(filename: images_to_delete, parent: parent).each do |image|
        self.class.info("Pixomatix::populate_images_from_directory Deleted Image: #{image.id} #{File.join(directory, image.filename)}", msg_to_stdout)
        image.destroy
      end

      images_to_create.each do |filename|
        filepath = File.join(directory, filename)
        image = MiniMagick::Image.open(filepath)
        new_image = Image.where(filename: filename, width: image.width, height: image.height, size: image.size, parent: parent, mime_type: image.mime_type).first_or_initialize
        new_image.save
        self.class.info("Pixomatix::populate_images_from_directory Added Image: #{new_image.id} #{filepath}", msg_to_stdout)
        image.destroy!
      end
      self.class.info("Pixomatix::populate_images_from_directory Finish for #{directory} Created: #{images_to_create.count} Deleted: #{images_to_delete.count}", msg_to_stdout)
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
