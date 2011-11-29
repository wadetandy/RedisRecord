require 'active_model'

module RedisRecord
  class Base
    extend ActiveModel::Naming

    include ActiveModel::Validations
  end
end
