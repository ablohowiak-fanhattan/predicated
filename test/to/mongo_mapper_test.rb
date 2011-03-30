require "./test/test_helper_with_wrong"
require "./test/canonical_transform_cases"

require "predicated/to/mongo_mapper"
include Predicated

class EmbeddedDoc
  include MongoMapper::EmbeddedDocument
  key :y, Integer
  key :z, Integer
end

class ExampleTypes
  include MongoMapper::Document
  key :a, Integer
  key :b, Integer
  key :c, Integer
  key :d, Boolean
  key :e, String
  many :x, :class_name => 'EmbeddedDoc'
end

regarding "convert a predicate to a mongo mapper structure" do
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
      "and with the same key" => {"a" => {'$all' => [1, 2]}},
      "and of same" => {"a" => {'$lt' => 5, '$gt' => 3}},
      "or" =>  {"$or" =>  [{"a" => 1}, {"b" => 2}] },
      "many or" =>  {"$or" =>  [{"a" => 1}, {"b" => 2}, {"c" => 3}] },
      "or of same" => {"a" => {"$in" => [1, 2]}},
      "many or of same" => {"a" => {"$in" => [1, 2, 3, 4]}}
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
      "and with the same key" => Predicate{ And(Eq("a", '1'),Eq("a", '2')) },
      "and of same" => Predicate{ And(Lt("a", '5'),Gt("a", '3')) },
      "and of same" => Predicate{ And(Lt("a", '5'),Gt("a", '3')) },
      "or" => Predicate{ Or(Eq("a", '1'),Eq("b", '2')) },
      "many or" => Predicate{ 
        Or( 
          Or( 
            Eq("a", '1'),
            Eq("b", '2') 
          ), 
          Eq("c", '3')
        ) 
      },
      "or of same" => Predicate{ Or(Eq("a", '1'),Eq("a", '2')) },
      "many or of same" => Predicate{ Or(Or(Or(Eq("a", '1'),Eq("a", '2')),Eq('a','3')), Eq('a', '4')) }
    },
    "complex and / or" => {
      "or and" => Predicate{ Or(And(Eq("a", '1'),Eq("b", '2')), Eq("c",'3')) }
    }
  }
  
  tests.each do |test_name, cases|
    test test_name do
      expectation = expectations[test_name]
      cases.each do |case_name, predicate|
        actual = predicate.to_mongo_mapper_struct(ExampleTypes)
        expected = expectation[case_name]
        assert { actual == expected }
      end
    end
  end
  
  test "'not' raises error" do
    predicate = Predicate{ Not(Eq("a",'3')) }
    assert_raises(Predicated::MongoMapperPredicateNotImplemented) { predicate.to_mongo_mapper_struct(ExampleTypes) }
  end
  
  regarding "embedded documents" do
    test "basic" do
      predicate = Predicate{ Eq('x.y', 1) }
      assert {
        predicate.to_mongo_mapper_struct(ExampleTypes) == 
        { 'x' => { '$elemMatch' => { 'y' => 1 } } }
      }
    end

    test "compound" do
      predicate = Predicate{ And(Eq('x.y', 1), Gt('x.z', 1)) }
      assert {
        predicate.to_mongo_mapper_struct(ExampleTypes) == 
        { 'x' => { '$elemMatch' => { 'y' => 1, 'z' => { '$gt' => 1 } } } }
      }
    end

    test "with OR" do
      predicate = Predicate{ Or(Eq('x.y', 1), Eq('x.y', 2)) }
      assert {
        predicate.to_mongo_mapper_struct(ExampleTypes) == 
        {'x' => {'$elemMatch' => {'y' => {'$in' => [1,2]}}}}
      }
    end    
  end
end