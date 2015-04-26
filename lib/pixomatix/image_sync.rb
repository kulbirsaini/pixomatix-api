module Pixomatix
  class ImageSync
    attr_accessor :directories

    def initialize(directories = nil)
      @directories = directories || IMAGE_ROOTS
    end

    def self.generate_thumbnails
      Image.images.each do |image|
        filepath = image.thumbnail_path
        next if File.exists?(filepath)
        image.scale(Rails.application.config.x.thumbnail_width, Rails.application.config.x.thumbnail_height, filepath)
        p filepath
      end
    end

    def self.generate_hdtv_images
      Image.images.each do |image|
        filepath = image.hdtv_path
        next if File.exists?(filepath)
        image.resize(Rails.application.config.x.hdtv_width, Rails.application.config.x.hdtv_height, filepath)
        p filepath
      end
    end

    def populate_images(directory = nil, parent = nil)
      if directory
        parent = Image.where(path: directory, parent: parent, filename: nil).first_or_create
        popuplate_images_from_directory(directory, parent)
        get_sub_directories(directory).each do |directory|
          populate_images(directory, parent)
        end
      else
        @directories.each do |directory|
          parent = Image.where(path: directory, filename: nil).first_or_create
          popuplate_images_from_directory(directory, parent)
          get_sub_directories(directory).each do |sub_directory|
            populate_images(sub_directory, parent)
          end
        end
      end
    end

    def popuplate_images_from_directory(directory, parent)
      Dir.foreach(directory).map do |filename|
        next if ['.', '..'].member?(filename)
        next if ['.mov', '.mpg', '.mpeg', '.dat', '.mp4', '.mp3', '.wmv', '.avi'].member?(File.extname(filename).downcase)
        filepath = File.join(directory, filename)
        begin
          image = MiniMagick::Image.open(filepath)
          Image.where(path: directory, filename: filename, width: image.width, height: image.height, size: image.size, parent: parent, mime_type: image.mime_type).first_or_create
          puts "Added #{filepath}"
          image.destroy!
          filepath
        rescue ActiveRecord::ActiveRecordError => e
          puts e.message
        rescue Exception => e
        end
      end.compact
    end

    def get_sub_directories(directory)
      Dir.foreach(directory).select{ |dir| !['.', '..'].member?(dir) }.map{ |dir| File.join(directory, dir) }.select{ |dir| File.directory?(dir) }.sort
    end

    def self.get_images_for_directory(directory)
      Dir.foreach(directory).map do |filename|
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
      end.compact
    end
  end
end
