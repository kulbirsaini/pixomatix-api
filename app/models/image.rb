class Image < ActiveRecord::Base
  validates :path, presence: true

  has_many :images, -> { where.not(filename: nil) }, class_name: 'Image', foreign_key: 'parent_id'
  has_many :children, -> { where(filename: nil) }, class_name: 'Image', foreign_key: 'parent_id'
  belongs_to :parent, class_name: 'Image', foreign_key: 'parent_id'

  scope :root, -> { where(parent_id: nil) }
  scope :images, -> { where.not(filename: nil) }
end
