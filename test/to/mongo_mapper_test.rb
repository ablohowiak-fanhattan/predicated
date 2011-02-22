require "./test/test_helper_with_wrong"
require "./test/canonical_transform_cases"

require "predicated/to/mongo_mapper"
include Predicated

regarding "convert a predicate to a json structure" do
  expectations = {
    "simple operations" => {
      "eq" => {"a" => 3},
      "gt" => {"a" => {'$gt' => 3}},
      "lt" => {"a" => {'$lt' => 3}},
      "gte" => {"a" => {'$gte' => 3}},
      "lte" => {"a" => {'$lte' => 3}}
    },
    "primitive types" => {
      "false" => {"d" => false},
      "true" => {"d" => true},
      "string" => {"e" => "yyy"}
    },
    "simple and / or" => {
      "and" => {"a" => 1, "b" => 2},
      "or" =>  {"$or" =>  [{"a" => 1}, {"b" => 2}] }
    },
    "complex and / or" => {
      "or and" => {"$or" =>  [
                    {"a" => 1, "b" => 2},
                    {"c" => 3}
                   ]}
    }
  }  
  
  tests = {
    "simple operations" => {
      "eq" => Predicate{ Eq("a",'3') },
      "gt" => Predicate{ Gt("a",'3') },
      "lt" => Predicate{ Lt("a",'3') },
      "gte" => Predicate{ Gte("a",'3') },
      "lte" => Predicate{ Lte("a",'3') }
    },
    "primitive types" => {
      "true" => Predicate{ Eq("d",'true') },
      "false" => Predicate{ Eq("d",'false') },
      "string" => Predicate{ Eq("e","yyy") },
    },
    "simple and / or" => {
      "and" => Predicate{ And(Eq("a", '1'),Eq("b", '2')) },
      "or" => Predicate{ Or(Eq("a", '1'),Eq("b", '2')) }
    },
    "complex and / or" => {
      "or and" => Predicate{ Or(And(Eq("a", '1'),Eq("b", '2')), Eq("c",'3')) }
    }
  }
  
  class ExampleTypes
    include MongoMapper::Document
    key :a, Integer
    key :b, Integer
    key :c, Integer
    key :d, Boolean
    key :e, String
  end

  tests.each do |test_name, cases|
    test test_name do
      cases.each do |case_name, predicate|
        actual = predicate.to_mongo_mapper_struct(ExampleTypes)
        assert { actual == expectations[test_name][case_name] }
      end
    end
  end
  
  test "'not' raises error" do
    predicate = Predicate{ Not(Eq("a",'3')) }
    assert_raises(Predicated::MongoMapperPredicateNotImplemented) { predicate.to_mongo_mapper_struct(ExampleTypes) }
  end
  
end