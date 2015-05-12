class ImagesController < ApplicationController
  include ImagesHelper

  before_action :set_image, only: [:show, :download, :galleries, :images, :image, :parent]

  # GET /images
  # GET /images.json
  def index
    @images = Image.root
  end

  def download
    send_file @image.original_path, type: @image.mime_type, disposition: 'attachment'
  end

  def original
    @image = Image.find(params[:id])
    image_path = @image.original_path || get_asset_path("default_gallery_image_original.png")
    send_file image_path, type: @image.try(:mime_type) || 'image/png', disposition: 'inline'
  end

  def galleries
    @galleries = @image.children
  end

  def images
    @images = @image.images.ordered
  end

  def image
    @first_image = @image.images.ordered.first
  end

  def parent
    @parent = @image.parent_with_galleries
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_image
      @image = Image.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def image_params
      params.require(:image).permit(:path, :filename, :width, :height, :size, :parent_id, :type)
    end
end
