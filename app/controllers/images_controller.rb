class ImagesController < ApplicationController
  include ImagesHelper

  before_action :set_image, only: [:show, :download, :galleries, :images, :image, :parent]

  # GET /images
  # GET /images.json
  def index
    @images = Image.root
  end

  def show
  end

  def download
    send_file @image.original_path, type: @image.mime_type, disposition: 'attachment'
  end

  def original
    @image = Image.find(params[:id])
    image_path = @image.original_path || get_asset_path("default_gallery_image_original.png")

    send_params = { type: @image.mime_type || 'image/png', disposition: :inline, stream: true, filename: "#{@image.id}#{File.extname(image_path)}" }

    response.headers["Pragma"] = "no-cache"
    response.headers["Accept-Ranges"]=  "bytes"
    response.headers["Expires"]= 6.months.from_now.httpdate
    response.headers["Content-Transfer-Encoding"] = "binary"

    response.last_modified = File.mtime(image_path)
    response.etag = @image
    response.cache_control.merge!( max_age: 6.months.to_i, public: true, must_revalidate: true )

    if request.headers["Range"]
      bytes = Rack::Utils.byte_ranges(request.headers, @image.size)[0]
      p bytes
      length = bytes.end - bytes.begin
      response.headers["Content-Range"] = "bytes #{bytes.begin}-#{bytes.end}/#{@image.size}"
      response.headers["Content-Length"] = (bytes.end - bytes.begin + 1).to_s

      send_data IO.binread(image_path, length, bytes.begin), send_params.merge( status: :partial_content )
    else
      response.headers["Content-Length"] = @image.size.to_s
      send_file image_path, send_params.merge( status: :ok )
    end
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
