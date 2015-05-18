module Pixomatix
  class ApiConstraints

    def initialize(options)
      @version = options[:version]
      @default = options[:default]
    end

    def matches?(req)
      @default || req.headers['Accept'].include?("application/vnd.pixomatix.v#{@version}")
    end
  end
end
