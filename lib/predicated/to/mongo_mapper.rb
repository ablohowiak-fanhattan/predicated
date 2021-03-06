require "predicated/predicate"

module Predicated
  require_gem_version("mongo_mapper", "0.9.0")
  
  class MongoMapperPredicateNotImplemented < StandardError; end
  
  module NestableBoolean
  private
    def collapse_similar(with_key, first, second)
      val = []
      if first.is_a?(Hash) && first.has_key?(with_key)
        val << first[with_key]
      else
        val << first
      end
      if second.is_a?(Hash) && second.has_key?(with_key)
        val << second[with_key]
      else
        val << second
      end
      val.flatten
    end
  end
  
  class And
    def to_mongo_mapper_struct(document_class)
      deep_merge(left.to_mongo_mapper_struct(document_class), right.to_mongo_mapper_struct(document_class))
    end
  private
    include NestableBoolean
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
        if first[key]
          target[key] = {'$all' => collapse_similar('$all', first[key], second[key])}
        else
          target[key] = second[key]
        end
      end

      target
    end
  end

  class Or
    def to_mongo_mapper_struct(document_class)
      # assume left and right are hashes
      aggregate_merge(left.to_mongo_mapper_struct(document_class), right.to_mongo_mapper_struct(document_class))
    end
    
  private
    include NestableBoolean
    def aggregate_merge(first, second)
      target = {}
      one_key = first.size == 1 && second.size == 1
      same_keys = first.keys.to_set == second.keys.to_set
      if !one_key || !same_keys
        target['$or'] = collapse_similar('$or', first, second)
        return target
      end

      # first and second have one identical key
      key = second.keys.first
      if first[key].is_a?(Hash) && second[key].is_a?(Hash)
        target[key] = aggregate_merge(first[key], second[key])
      else
        collapsed_hash = collapse_similar('$in', first[key], second[key])
        target[key] = key.eql?('$in') ? collapsed_hash : { '$in' => collapsed_hash }
      end
      target
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
      document_class.keys[left].set(right)
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