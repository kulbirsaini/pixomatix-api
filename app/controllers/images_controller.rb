class ImagesController < ApplicationController
  include ImagesHelper

  before_action :set_image, only: [:show, :galleries, :images, :parent]

  # GET /images
  # GET /images.json
  def index
    @images = Image.root
  end

  # GET /images/1
  # GET /images/1.json
  def show
    render 'show_image', layout: false && return if @image.image? && params.has_key?(:show)
  end

  def thumbnail
    begin
      @image = Image.find(params[:id])
      image_path = @image.get_random_image.get_path(:thumbnail)
    rescue
      image_path = get_asset_path("default_gallery_image_thumbnail.png")
    end
    send_file image_path, type: @image.try(:mime_type) || 'image/png', disposition: 'inline'
  end

  def hdtv
    begin
      @image = Image.find(params[:id])
      image_path = @image.get_random_image.get_path(:hdtv)
    rescue
      image_path = get_asset_path("default_gallery_image_hdtv.png")
    end
    send_file image_path, type: @image.try(:mime_type) || 'image/png', disposition: 'inline'
  end

  def original
    begin
      @image = Image.find(params[:id])
      image_path = @image.get_random_image.get_path(:original)
    rescue
      image_path = get_asset_path("default_gallery_image_original.png")
    end
    send_file image_path, type: @image.try(:mime_type) || 'image/png', disposition: 'inline'
  end

  def galleries
    @galleries = @image.children
  end

  def images
    @images = @image.images
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
