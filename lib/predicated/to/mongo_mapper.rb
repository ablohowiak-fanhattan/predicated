require "predicated/predicate"

module Predicated
  require_gem_version("mongo_mapper", "0.8.6")
  
  class MongoMapperPredicateNotImplemented < StandardError; end
  
  class Predicate
    def cast_right_to_mongo_mapper_type(document_class)
      document_class.keys[left.to_sym].set(right)
    end
  end
  
  class And
    def to_mongo_mapper_struct(document_class)
      left.to_mongo_mapper_struct(document_class).merge right.to_mongo_mapper_struct(document_class)
    end
  end

  class Or
    def to_mongo_mapper_struct(document_class)
      {"$or" => [left.to_mongo_mapper_struct(document_class), right.to_mongo_mapper_struct(document_class)]}
    end
  end

  class Not
    def to_mongo_mapper_struct(document_class)
      raise MongoMapperPredicateNotImplemented
    end
  end
  
  class Operation
    def to_mongo_mapper_struct(document_class)
      {left => {mongo_mapper_sign => cast_right_to_mongo_mapper_type(document_class)}}
    end
  end

  class Equal
    def to_mongo_mapper_struct(document_class)
      {left => cast_right_to_mongo_mapper_type(document_class)}
    end
  end
  class LessThan; private; def mongo_mapper_sign; "$lt" end end
  class GreaterThan; private; def mongo_mapper_sign; "$gt" end end
  class LessThanOrEqualTo; private; def mongo_mapper_sign; "$lte" end end
  class GreaterThanOrEqualTo; private; def mongo_mapper_sign; "$gte" end end
  

end