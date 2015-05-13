module Pixomatix
  module Common
    def info(message, msg_to_stdout = false)
      Rails.logger.info message
      puts message if msg_to_stdout
    end

    def debug(message, msg_to_stdout = false)
      Rails.logger.debug message
      puts message if msg_to_stdout
    end
  end
end
