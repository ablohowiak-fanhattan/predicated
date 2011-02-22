require "predicated/predicate"

module Predicated
  require_gem_version("mongo_mapper", "0.8.6")
  
  class MongoMapperPredicateNotImplemented < StandardError; end
  
  class And
    def to_mongo_mapper_struct(document_class)
      deep_merge(left.to_mongo_mapper_struct(document_class), right.to_mongo_mapper_struct(document_class))
    end
  private
    # Merges two hashes, recursively.
    # 
    # This code was lovingly stolen from some random gem:
    # http://gemjack.com/gems/tartan-0.1.1/classes/Hash.html
    # 
    # Thanks to whoever made it.

    def deep_merge(first, second)
      target = first.dup

      second.keys.each do |key|
        if second[key].is_a? Hash and first[key].is_a? Hash
          target[key] = deep_merge(target[key], second[key])
          next
        end

        target[key] = second[key]
      end

      target
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
      if left.to_s.include?('.')
        to_nested_mongo_mapper_struct(document_class)
      else
        to_unnested_mongo_mapper_struct(document_class)
      end
    end

    private
    
    def to_unnested_mongo_mapper_struct(document_class)
      {left => {mongo_mapper_sign => cast_right_to_mongo_mapper_type(document_class)}}
    end
    
    def cast_right_to_mongo_mapper_type(document_class)
      document_class.keys[left.to_sym].set(right)
    end
    
    def to_nested_mongo_mapper_struct(document_class)
      key, *rest = left.split('.')
      child_class = document_class.associations[key.to_sym].klass
      sub_predicate = self.class.new(rest.join('.'), right)
      {key => {'$elemMatch' => sub_predicate.to_mongo_mapper_struct(child_class)}}
    end
  end

  class Equal
    def to_unnested_mongo_mapper_struct(document_class)
      {left => cast_right_to_mongo_mapper_type(document_class)}
    end
  end
  class LessThan; private; def mongo_mapper_sign; "$lt" end end
  class GreaterThan; private; def mongo_mapper_sign; "$gt" end end
  class LessThanOrEqualTo; private; def mongo_mapper_sign; "$lte" end end
  class GreaterThanOrEqualTo; private; def mongo_mapper_sign; "$gte" end end
  

end