class ImagesController < ApplicationController
  before_action :set_image, only: [:show, :stream]

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

  def stream
    if @image.image?
      if params[:show].present?
        render 'show_image', layout: false
        return
      else
        if params[:type] == :original
          image_path = @image.original_path
          image_path = File.join(Rails.root, 'app/assets/images/', 'default_gallery_image_original.png') unless File.exists?(image_path)
        elsif params[:type] == :hdtv
          image_path = @image.hdtv_path
          image_path = @image.original_path unless File.exists?(image_path)
          image_path = File.join(Rails.root, 'app/assets/images/', 'default_gallery_image_hdtv.png') unless File.exists?(image_path)
        else
          image_path = @image.thumbnail_path
          image_path = File.join(Rails.root, 'app/assets/images/', 'default_gallery_image_thumbnail.png') unless File.exists?(image_path)
        end
        send_file image_path, type: @image.mime_type, disposition: 'inline'
      end
    end
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
