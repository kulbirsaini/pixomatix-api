class Image < ActiveRecord::Base
  validates :path, presence: true

  has_many :images, -> { where.not(filename: nil) }, class_name: 'Image', foreign_key: 'parent_id'
  has_many :children, -> { where(filename: nil) }, class_name: 'Image', foreign_key: 'parent_id'
  belongs_to :parent, class_name: 'Image', foreign_key: 'parent_id'

  scope :root, -> { where(parent_id: nil) }
  scope :images, -> { where.not(filename: nil) }
  scope :ordered, -> { order(:filename) }

  def directory_tree
    return nil if !image?
    parents = []
    next_parent = parent
    while next_parent
      parents << next_parent.id
      next_parent = next_parent.parent
    end
    parents.compact.reverse.join('/')
  end

  def image?
    !filename.nil?
  end

  def scale(width, height, filepath)
    return nil if !image?
    FileUtils.mkdir_p(File.dirname(filepath))
    image = Magick::Image.read(File.join(self.path, self.filename)).first
    image.scale!(width, height)
    image.write(filepath)
    image.destroy!
    nil
  end

  def resize(width, height, filepath)
    return nil if !image?
    FileUtils.mkdir_p(File.dirname(filepath))
    image = MiniMagick::Image.open(File.join(self.path, self.filename))
    rotated = image.height > image.width
    image.rotate(90) if rotated
    image.resize(width) if width < image.width
    if height < image.height
      image.rotate(90)
      image.resize(height)
      image.rotate(-90)
    end
    image.rotate(-90) if rotated
    image.write(filepath)
    image.destroy!
    nil
  end

  def thumbnail_path
    File.join(Rails.root,
              Rails.application.config.x.image_cache_dir,
              self.directory_tree,
              self.id.to_s + '_' +
                Rails.application.config.x.thumbnail_width.to_s + 'x' +
                Rails.application.config.x.thumbnail_height.to_s +
                File.extname(self.filename))
  end

  def hdtv_path
    File.join(Rails.root,
              Rails.application.config.x.image_cache_dir,
              self.directory_tree,
              self.id.to_s + '_' +
                Rails.application.config.x.hdtv_width.to_s + 'x' +
                Rails.application.config.x.hdtv_height.to_s +
                File.extname(self.filename))
  end

  def original_path
    File.join(self.path, self.filename)
  end
end
