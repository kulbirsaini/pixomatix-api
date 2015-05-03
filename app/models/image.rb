class Image < ActiveRecord::Base
  has_many :images, -> { where.not(filename: nil) }, class_name: 'Image', foreign_key: 'parent_id'
  has_many :children, -> { where(filename: nil) }, class_name: 'Image', foreign_key: 'parent_id'
  belongs_to :parent, class_name: 'Image', foreign_key: 'parent_id'

  scope :root, -> { where(parent_id: nil) }
  scope :images, -> { where.not(filename: nil) }
  scope :ordered, -> { order(:filename) }

  after_create :update_parent
  after_save :update_parent
  after_destroy :update_parent

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
    if index
      return nil if parent_id.nil?
      parent_id.to_s
    else
      return nil if !parent.path.present?
      parent.path
    end
  end

  def root?
    parent_id.nil?
  end

  def image?
    !filename.nil?
  end

  def gallery?
    filename.nil?
  end

  def has_parent?
    parent_id.present?
  end

  def parent_with_galleries
    return self if has_galleries?
    return parent.parent_with_galleries if parent
  end

  def scale(width, height, filepath)
    return nil if !image?
    FileUtils.mkdir_p(File.dirname(filepath))
    image = Magick::Image.read(self.original_path).first
    image.scale!(width, height)
    image.write(filepath)
    image.destroy!
    true
  end

  def resize_to_hdtv(height, filepath)
    return nil if !image?
    if self.width >= self.height
      if self.height <= height
        return
      end
    else
      if self.width <= height
        return
      end
    end

    image = MiniMagick::Image.open(self.original_path)
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
    true
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

  def get_random_image
    return self if image?
    return images.first if images.first
    children.each do |child|
      image = child.get_random_image
      return image if image && image.image?
    end
    nil
  end

  def get_path(type)
    return get_asset_path('default_gallery_image_thumbnail.png') if !image?
    type = type.to_s
    case type
    when 'original'
      return original_path if File.exists?(original_path)
      return get_asset_path('default_gallery_image_original.png')
    when 'hdtv'
      return hdtv_path if File.exists?(hdtv_path)
      return original_path if File.exists?(original_path)
      return get_asset_path('default_gallery_image_hdtv.png')
    when 'thumbnail'
      return thumbnail_path if File.exists?(thumbnail_path)
      return get_asset_path('default_gallery_image_thumbnail.png')
    end
    get_asset_path('default_gallery_image_thumbnail.png')
  end

  private

  def update_parent
    return unless parent
    parent.update(has_galleries: parent.children.count > 0, has_images: parent.images.count > 0)
  end
end
