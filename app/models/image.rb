class Image < ActiveRecord::Base
  has_many :photos, -> { where.not(filename: nil) }, class_name: 'Image', foreign_key: 'parent_id'
  has_many :galleries, -> { where(filename: nil).order(:path) }, class_name: 'Image', foreign_key: 'parent_id'
  belongs_to :parent, class_name: 'Image', foreign_key: 'parent_id'
  belongs_to :user

  scope :root, -> { where(parent_id: nil) }
  scope :photos, -> { where.not(filename: nil) }
  scope :ordered, -> { order(:filename, :path) }

  after_create :update_parent
  after_save :update_parent
  after_destroy :update_parent

  validates :uid, presence: true, uniqueness: true
  #FIXME populate images need to be synced before enabling this validation
  #validates :user_id, presence: true, numericality: { only_integer: true, greater_than: 0 }

  def directory_tree(index = false)
    parents = []
    next_parent = photo? ? parent : self
    while next_parent
      if index
        parents << next_parent.uid
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
      parent.uid
    else
      return nil if !parent.path.present?
      parent.path
    end
  end

  def root?
    parent_id.nil?
  end

  def photo?
    !filename.nil?
  end

  def vertical?
    photo? && height > width
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
    return nil if !photo?
    FileUtils.mkdir_p(File.dirname(filepath))
    image = Magick::Image.read(self.original_path).first
    image.scale!(width, height)
    image.write(filepath)
    image.destroy!
    true
  end

  def resize_to_hdtv(height, filepath)
    return nil if !photo?
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

  def absolute_thumbnail_path
    return nil unless photo?
    File.join(Rails.application.config.x.image_cache_dir,
              self.parent_directory(true),
              self.uid.to_s + '_' +
              Rails.application.config.x.thumbnail_width.to_s + 'x' +
              Rails.application.config.x.thumbnail_height.to_s +
              File.extname(self.filename))
  end

  def thumbnail_path
    return nil unless photo?
    return aws_thumb_url if aws_thumb_url.present? && Rails.application.config.x.use_aws
    path = File.join(Rails.application.config.x.image_cache_path_prefix,
              self.parent_directory(true),
              self.uid.to_s + '_' +
              Rails.application.config.x.thumbnail_width.to_s + 'x' +
              Rails.application.config.x.thumbnail_height.to_s +
              File.extname(self.filename))
    File.exists?(File.join(Rails.root, 'public', path)) ? path : nil
  end

  def absolute_hdtv_path
    return nil unless photo?
    File.join(Rails.application.config.x.image_cache_dir,
              self.parent_directory(true),
              self.uid.to_s + '_' +
                Rails.application.config.x.hdtv_height.to_s +
                File.extname(self.filename))
  end

  def hdtv_path
    return nil unless photo?
    return aws_hdtv_url if aws_hdtv_url.present? && Rails.application.config.x.use_aws
    path = File.join(Rails.application.config.x.image_cache_path_prefix,
              self.parent_directory(true),
              self.uid.to_s + '_' +
                Rails.application.config.x.hdtv_height.to_s +
                File.extname(self.filename))
    File.exists?(File.join(Rails.root, 'public', path)) ? path : nil
  end

  def original_path
    return nil unless photo?
    path = File.join(self.directory_tree, self.filename)
    File.exists?(path) ? path : nil
  end

  def caption
    path = self.path
    return nil if path.nil?
    path = path.split('/')[-1] if path.include?('/')
    path.gsub('_', ' ').gsub(/^[0-9]+ /, '').gsub(/^[0-9]+\. /, '').titleize
  end

  def get_random_photo
    return self if photo?
    return photos.limit(1).order('RAND()').first if photos.first
    galleries.each do |gallery|
      image = gallery.get_random_photo
      return image if image && image.photo?
    end
    nil
  end

  private

  def update_parent
    return unless parent
    parent.has_galleries = parent.galleries.first.present?
    parent.has_photos = parent.photos.first.present?
    parent.save
  end
end
