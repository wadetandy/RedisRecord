require 'active_model'

module RedisRecord
  class Base
    extend ActiveModel::Naming

    include ActiveModel::Validations
    include ActiveModel::Conversion
    include ActiveModel::MassAssignmentSecurity
    include ActiveModel::Dirty
  end
end
