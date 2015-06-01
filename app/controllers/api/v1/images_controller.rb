class Api::V1::ImagesController < Api::V1::BaseController
  before_action :authenticate!, only: [] #FIXME remove this later to enable authentication
  before_action :set_image, only: [:show, :original, :download, :galleries, :photos, :photo, :parent]

  # GET /images.json
  def index
    @galleries = Image.root.count > 1 ? Image.root : Image.root.first.galleries
  end

  def show
  end

  def original
    if @image.original_path.present?
      image_path = @image.original_path
      size = @image.size
      mime_type = @image.mime_type
      filename = "#{@image.uid}#{File.extname(image_path)}"
      response.headers["Accept-Ranges"]=  "bytes"
      response.etag = @image
    else
      image_path = File.join(Rails.root, 'app/assets/images/default_gallery_image_original.png')
      size = File.size(image_path)
      mime_type = 'image/png'
      filename = 'default_gallery_image_original.png'
      response.etag = Digest::MD5.hexdigest(filename)
    end

    send_params = { type: mime_type, disposition: :inline, stream: true, filename: filename }

    response.headers["Content-Transfer-Encoding"] = "binary"
    response.last_modified = File.mtime(image_path)
    response.headers["Pragma"] = "no-cache"
    response.headers["Expires"]= 6.months.from_now.httpdate
    response.cache_control.merge!( max_age: 6.months.to_i, public: true, must_revalidate: true )

    if request.headers["Range"].present?
      bytes = Rack::Utils.byte_ranges(request.headers, size)[0]
      length = bytes.end - bytes.begin
      response.headers["Content-Range"] = "bytes #{bytes.begin}-#{bytes.end}/#{size}"
      response.headers["Content-Length"] = (bytes.end - bytes.begin + 1).to_s

      send_data IO.binread(image_path, length, bytes.begin), send_params.merge( status: :partial_content )
    else
      response.headers["Content-Length"] = size.to_s
      send_file image_path, send_params.merge( status: :ok )
    end
  end

  def download
    send_file @image.original_path, type: @image.mime_type, disposition: 'attachment'
  end

  def galleries
    @galleries = @image.galleries
  end

  def photos
    @photos = @image.photos.ordered
  end

  def photo
    @first_photo = @image.photos.ordered.first
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
