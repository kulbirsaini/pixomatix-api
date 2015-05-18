module Api
  module V1
    module ImagesHelper
      def get_absolute_url_for(path)
        return path if path =~ /^http:/ || path =~ /^https:/
        File.join(request.base_url, path)
      end
    end
  end
end
