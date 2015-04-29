class Image < ActiveRecord::Base
  has_many :images, -> { where.not(filename: nil) }, class_name: 'Image', foreign_key: 'parent_id'
  has_many :children, -> { where(filename: nil) }, class_name: 'Image', foreign_key: 'parent_id'
  belongs_to :parent, class_name: 'Image', foreign_key: 'parent_id'

  scope :root, -> { where(parent_id: nil) }
  scope :images, -> { where.not(filename: nil) }
  scope :ordered, -> { order(:filename) }

  def directory_tree(index = false)
    parents = []
    next_parent = parent
    while next_parent
      if index
        parents << next_parent.id.to_s
      else
        parents << next_parent.path
      end
      next_parent = next_parent.parent
    end
    File.join(parents.compact.reverse)
  end

  def parent_directory(index = false)
    return nil if parent.nil? || !parent.path.present?
    index ? parent.id.to_s : parent.path
  end

  def image?
    !filename.nil?
  end

  def scale(width, height, filepath)
    return nil if !image?
    FileUtils.mkdir_p(File.dirname(filepath))
    image = Magick::Image.read(self.original_path).first
    image.scale!(width, height)
    image.write(filepath)
    image.destroy!
    nil
  end

  def resize_to_hdtv(height, filepath)
    return nil if !image?
    image = MiniMagick::Image.open(self.original_path)
    if image.width >= image.height
      if image.height <= height
        image.destroy!
        return
      end
    else
      if image.width <= height
        image.destroy!
        return
      end
    end

    FileUtils.mkdir_p(File.dirname(filepath))
    if image.width >= image.height
      image.rotate(90)
      image.resize(height)
      image.rotate(-90)
    else
      image.resize(height)
    end
    image.write(filepath)
    image.destroy!
    nil
  end

  def thumbnail_path
    File.join(Rails.root,
              Rails.application.config.x.image_cache_dir,
              self.parent_directory(true),
              self.id.to_s + '_' +
                Rails.application.config.x.thumbnail_width.to_s + 'x' +
                Rails.application.config.x.thumbnail_height.to_s +
                File.extname(self.filename))
  end

  def hdtv_path
    File.join(Rails.root,
              Rails.application.config.x.image_cache_dir,
              self.parent_directory(true),
              self.id.to_s + '_' +
                Rails.application.config.x.hdtv_height.to_s +
                File.extname(self.filename))
  end

  def original_path
    if image?
      File.join(self.directory_tree, self.filename)
    else
      File.join(self.directory_tree, self.path)
    end
  end
end
