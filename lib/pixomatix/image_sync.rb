module Pixomatix
  class ImageSync
    extend Pixomatix::Common
    attr_reader :directories

    def initialize(directories = nil)
      directories = directories.present? ? [ directories ].flatten : nil
      @directories = directories || Rails.application.config.x.image_root
    end

    def self.unique_id_for_text(data)
      # We use MD5 instead of uuid/SecureRandom because we want to retain the id on rescan.
      Digest::MD5.hexdigest(data).first(16)
    end

    def self.unique_id_for_file(filepath)
      self.unique_id_for_text(filepath + File.read(filepath))
    end

    def self.parse_filename(filename)
      result = filename.scan(Rails.application.config.x.thumbnail_path_regex)[0]
      if result.present?
        return { type: :thumbnail, uid: result[0], width: result[1], height: result[2] }
      end
      result = filename.scan(Rails.application.config.x.hdtv_path_regex)[0]
      if result.present?
        return { type: :hdtv, uid: result[0], hdtv_height: result[1] }
      end
    end

    def self.optimize_cache(msg_to_stdout = false)
      image_cache_dir = Rails.application.config.x.image_cache_dir
      self.info("ImageSync::optimize_cache Start optimize_cache image_cache_dir: #{image_cache_dir}", msg_to_stdout)
      self.get_sub_directories(image_cache_dir).each do |sub_directory|
        directory = File.join(image_cache_dir, sub_directory)
        self.info("ImageSync::optimize_cache Optimizing cache for #{directory}", msg_to_stdout)
        Dir.entries(directory).each do |filename|
          next unless self.is_image_extension?(filename)
          filepath = File.join(directory, filename)
          keep_file = false
          if result = self.parse_filename(filename)
            if image = Image.where(uid: result[:uid]).first
              keep_file = true if image.send("absolute_#{result[:type].to_s}_path") == filepath
            end
          end
          unless keep_file
            FileUtils.rm(filepath)
            self.info("ImageSync::optimize_cache Removed file #{filepath}", msg_to_stdout)
          end
        end
        if Dir.entries(directory).size == 2
          FileUtils.rmdir(directory)
          self.info("ImageSync::optimize_cache Removed directory #{directory}", msg_to_stdout)
        end
      end
      self.info("ImageSync::optimize_cache Finish optimize_cache image_cache_dir: #{image_cache_dir}", msg_to_stdout)
      nil
    end

    def self.generate_thumbnails(images = nil, msg_to_stdout = false)
      self.info("ImageSync::generate_thumbnails Start", msg_to_stdout)
      (images || Image.photos).each do |image|
        filepath = image.absolute_thumbnail_path
        if File.exists?(filepath)
          self.info("ImageSync::generate_thumbnails Exists at #{filepath} for Image: #{image.id}", msg_to_stdout)
          next
        end
        if image.scale(Rails.application.config.x.thumbnail_width, Rails.application.config.x.thumbnail_height, filepath)
          self.info("ImageSync::generate_thumbnails Created at #{filepath} for Image: #{image.id}", msg_to_stdout)
        else
          self.info("ImageSync::generate_thumbnails Not required for Image: #{image.id}", msg_to_stdout)
        end
      end
      self.info("ImageSync::generate_thumbnails Finish", msg_to_stdout)
      nil
    end

    def self.generate_hdtv_images(images = nil, msg_to_stdout = false)
      self.info("ImageSync::generate_hdtv_images Start", msg_to_stdout)
      (images || Image.photos).each do |image|
        filepath = image.absolute_hdtv_path
        if File.exists?(filepath)
          self.info("ImageSync::generate_hdtv_images Exists at #{filepath} for Image: #{image.id}", msg_to_stdout)
          next
        end
        if image.resize_to_hdtv(Rails.application.config.x.hdtv_height, filepath)
          self.info("ImageSync::generate_hdtv_images Created at #{filepath} for Image: #{image.id}", msg_to_stdout)
        else
          self.info("ImageSync::generate_hdtv_images Not required for Image: #{image.id}", msg_to_stdout)
        end
      end
      self.info("ImageSync::generate_hdtv_images Finish", msg_to_stdout)
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
      self.class.info("ImageSync::fix_exif_data Start for #{directory}", msg_to_stdout)
      timezone = Time.now.zone
      prev_datatime = nil

      Dir.entries(directory).sort.map do |filename|
        next unless self.class.is_image_extension?(filename)
        filepath = File.join(directory, filename)
        image = MiniMagick::Image.open(filepath)
        datetime = image.exif['DateTimeOriginal'] || image.exif['DateTime']
        image.destroy!

        if datetime.nil? && prev_datatime.nil?
          self.class.info("ImageSync::fix_exif_data Failed. Not enough data. Halting...!", msg_to_stdout)
          return
        elsif datetime.nil?
          self.class.info("ImageSync::fix_exif_data Fixing EXIF data for #{filepath}", msg_to_stdout)
          image_exif = MiniExiftool.new(filepath)
          datetime = (DateTime.strptime(prev_datatime + " #{timezone}", "%Y:%m:%d %H:%M:%S %Z").to_time + 1).to_s(:db)
          image_exif[:date_time_original] = datetime
          image_exif.save
        end
        prev_datatime = datetime
      end
      true
    rescue Exception => e
      self.class.info("ImageSync::fix_exif_data Error for #{directory}", msg_to_stdout)
      self.class.debug("ImageSync::fix_exif_data Trace\n#{e.backtrace.join("\n")}", msg_to_stdout)
      raise e
    ensure
      self.class.info("ImageSync::fix_exif_data Finish for #{directory}", msg_to_stdout)
    end

    def rename_images_from_directory_wrapper(directory, msg_to_stdout = false)
      begin
        rename_images_from_directory(directory, msg_to_stdout)
      rescue
        rename_images_from_directory(directory, msg_to_stdout) if fix_exif_data(directory, msg_to_stdout)
      end
    end

    def rename_images_from_directory(directory, msg_to_stdout = false)
      self.class.info("ImageSync::rename_images_from_directory Start #{directory}", msg_to_stdout)
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
        self.class.info("ImageSync::rename_images_from_directory Not required", msg_to_stdout)
        return
      end

      tmp_dir = "tmp/#{SecureRandom.hex(10)}-removable"
      tmp_dir_path = File.join(Rails.application.config.x.image_cache_dir, tmp_dir)
      FileUtils.mkdir_p(tmp_dir_path)
      self.class.info("ImageSync::rename_images_from_directory Created tmp directory #{tmp_dir_path}", msg_to_stdout)
      images.each do |image|
        image[:tmp_filepath] = File.join(tmp_dir_path, image[:filename])
        FileUtils.mv(image[:filepath], image[:tmp_filepath])
        self.class.info("ImageSync::rename_images_from_directory #{image[:filepath]} => #{image[:tmp_filepath]}", msg_to_stdout)
      end
      images.each do |image|
        FileUtils.mv(image[:tmp_filepath], image[:new_filepath])
        self.class.info("ImageSync::rename_images_from_directory #{image[:tmp_filepath]} => #{image[:new_filepath]}", msg_to_stdout)
      end
      FileUtils.rmdir(tmp_dir_path)
      self.class.info("ImageSync::rename_images_from_directory Removed tmp directory #{tmp_dir_path}", msg_to_stdout)
    rescue Exception => e
      self.class.info("ImageSync::rename_images_from_directory Error for #{directory}", msg_to_stdout)
      self.class.debug("ImageSync::rename_images_from_directory Trace\n#{e.backtrace.join("\n")}", msg_to_stdout)
      raise e
    ensure
      self.class.info("ImageSync::rename_images_from_directory Finish #{directory}", msg_to_stdout)
    end

    def create_gallery(directory, parent_gallery)
      gallery = Image.where(path: directory, parent: parent_gallery).first_or_initialize
      gallery.uid = self.class.unique_id_for_text(File.join(parent_gallery.try(:directory_tree).to_s, directory))
      gallery
    end

    def populate_images(directory = nil, parent_gallery = nil, msg_to_stdout = false)
      self.class.info("ImageSync::populate_images Start", msg_to_stdout) unless parent_gallery
      if directory
        cur_directory = parent_gallery.present? ? File.join(parent_gallery.directory_tree, directory) : directory
        gallery = create_gallery(directory, parent_gallery)
        unless gallery.save
          self.class.info("ImageSync::populate_images no gallery for #{directory}, parent_id: #{parent_gallery.id}, errors: #{gallery.errors.messages}", msg_to_stdout)
          return
        end
        populate_images_from_directory(directory, parent_gallery, msg_to_stdout)
        self.class.get_sub_directories(cur_directory).each do |sub_directory|
          populate_images(sub_directory, gallery, msg_to_stdout)
        end
        if gallery.galleries.count == 0 && gallery.photos.count == 0
          self.class.info("ImageSync::populate_images Removed gallery: #{gallery.id}", msg_to_stdout)
          gallery.destroy
        end
      else
        @directories.each do |directory|
          gallery = create_gallery(directory, parent_gallery)
          unless gallery.save
            self.class.info("ImageSync::populate_images no gallery for #{directory}, parent_id: #{parent_gallery.try(:id)}, errors: #{gallery.errors.messages}", msg_to_stdout)
            return
          end
          populate_images_from_directory(directory, parent_gallery, msg_to_stdout)
          self.class.get_sub_directories(directory).each do |sub_directory|
            populate_images(sub_directory, gallery, msg_to_stdout)
          end
          if gallery.galleries.count == 0 && gallery.photos.count == 0
            self.class.info("ImageSync::populate_images Removed gallery: #{gallery.id}", msg_to_stdout)
            gallery.destroy
          end
        end
      end
      self.class.info("ImageSync::populate_images Finish", msg_to_stdout) unless parent_gallery
    end

    def populate_images_from_directory(directory, parent_gallery, msg_to_stdout = false)
      gallery = create_gallery(directory, parent_gallery)
      unless gallery.save
        self.class.info("ImageSync::populate_images_from_directory no gallery for #{directory}, parent_id: #{parent_gallery.try(:id)}, errors: #{gallery.errors.messages}", msg_to_stdout)
        return
      end
      directory = gallery.directory_tree
      self.class.info("ImageSync::populate_images_from_directory Start for #{directory}, parent_id: #{parent_gallery.try(:id)}", msg_to_stdout)
      images_in_dir = Dir.entries(directory)
                      .select{ |filename| self.class.is_image_extension?(filename) }
                      .sort
                      .inject({}) do |result, filename|
                        filepath = File.join(directory, filename)
                        result[self.class.unique_id_for_file(filepath)] = { filename: filename, filepath: filepath }
                        result
                      end

      gallery.photos.where.not(uid: images_in_dir.keys).each do |image|
        self.class.info("ImageSync::populate_images_from_directory Deleted Image: #{image.id} #{File.join(directory, image.filename)}", msg_to_stdout)
        image.destroy
      end
      images_in_dir.each do |uid, data|
        new_image = gallery.photos.where(uid: uid).first
        if new_image
          new_image.filename = data[:filename]
        else
          image = MiniMagick::Image.open(data[:filepath])
          new_image = gallery.photos.where(filename: data[:filename], uid: uid, width: image.width, height: image.height, size: image.size, mime_type: image.mime_type).first_or_initialize
          image.destroy!
        end
        if new_image.save
          self.class.info("ImageSync::populate_images_from_directory Added Image: #{new_image.id} #{data[:filepath]}", msg_to_stdout)
        else
          self.class.info("ImageSync::populate_images_from_directory Error while adding image #{data[:filepath]}, errors: #{new_image.errors.messages}", msg_to_stdout)
        end
      end
      self.class.info("ImageSync::populate_images_from_directory Finish for #{directory} Total: #{images_in_dir.count}", msg_to_stdout)
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
