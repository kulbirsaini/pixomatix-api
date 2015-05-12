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

    file_begin = 0
    file_size = File.size(image_path)
    file_end = file_size - 1

    status_code = :ok
    if request.headers["Range"]
      status_code = :partial_content
      match = request.headers['range'].match(/bytes=(\d+)-(\d*)/)
      if match
        file_begin = match[1]
        file_end = match[1] if match[2] && !match[2].empty?
      end
      response.headers["Content-Range"] = "bytes " + file_begin.to_s + "-" + file_end.to_s + "/" + file_size.to_s
    end

    response.headers["Content-Length"] = (file_end.to_i - file_begin.to_i + 1).to_s
    response.headers["Pragma"] = "no-cache"
    response.headers["Accept-Ranges"]=  "bytes"
    response.headers["Expires"]= CGI.rfc1123_date(Time.now + 6.months)
    response.headers["Content-Transfer-Encoding"] = "binary"

    response.last_modified = File.mtime(image_path)
    response.etag = @image
    response.cache_control.merge!( max_age: 6.months.to_i, public: true, must_revalidate: true )

    send_file image_path, type: @image.try(:mime_type) || 'image/png',
                          disposition: 'inline',
                          status: status_code,
                          filename: "#{@image.id}#{File.extname(image_path)}"
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
