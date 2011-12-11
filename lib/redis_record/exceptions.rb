module RedisRecord
  module Exceptions
    class PropertyExists < StandardError; end
    class InvalidPropertyOption < StandardError; end
    class NotUnique < StandardError; end
    class UnknownAttribute < StandardError; end
  end
end
