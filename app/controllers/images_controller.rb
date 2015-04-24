class ImagesController < ApplicationController
  before_action :set_image, only: [:show]

  # GET /images
  # GET /images.json
  def index
    @images = Image.root
  end

  # GET /images/1
  # GET /images/1.json
  def show
    if @image.filename.present?
      send_file File.join(@image.path, @image.filename), type: @image.mime_type, disposition: 'inline'
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_image
      @image = Image.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def image_params
      params.require(:image).permit(:path, :filename, :width, :height, :size, :parent_id)
    end
end
