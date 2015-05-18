class Api::V1::ImagesController < Api::V1::BaseController
  before_action :set_image, only: [:show, :galleries, :images, :image, :parent]

  # GET /images.json
  def index
    @images = Image.root
  end

  def show
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
      @image = Image.where(uid: params[:id]).first
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def image_params
      params.require(:image).permit(:path, :filename, :width, :height, :size, :parent_id, :type, :uid)
    end
end
