require "test/test_helper"
require "test/canonical_transform_cases"

require "predicated/from/callable_object"
include Predicated

apropos "convert a ruby callable object - a proc or lambda - into a predicate" do



  apropos "basic operations" do
                                             
    test "complex types" do
      assert_equal Predicate.from_callable_object{Color.new("red")==Color.new("blue")}, 
        Predicate{ Eq(Color.new("red"),Color.new("blue")) }
    
      assert_equal Predicate.from_callable_object{ {1=>2}=={"a"=>"b"} }, 
        Predicate{ Eq({1=>2},{"a"=>"b"}) }
    end                                      
                                             
    test "word and / or" do                
      assert_equal Predicate.from_callable_object{1==1 and 2==2}, Predicate{ And(Eq(1,1),Eq(2,2)) }
      assert_equal Predicate.from_callable_object{1==1 or 2==2}, Predicate{ Or(Eq(1,1),Eq(2,2)) }
    end
    
    class Color
      attr_reader :name
      def initialize(name)
        @name = name
      end
    
      def ==(other)
        other.is_a?(Color) && @name == other.name
      end
    end
    
    test "substitute in from the binding" do
      a = 1
      b = "1"
      c = "c"
      d = Color.new("purple")
      
      assert_equal Predicate.from_callable_object(binding()){a==1}, Predicate{ Eq(1,1) }
      assert_equal Predicate.from_callable_object(binding()){b==1}, Predicate{ Eq("1",1) }
      assert_equal Predicate.from_callable_object(binding()){c==b}, Predicate{ Eq("c","1") }
      assert_equal Predicate.from_callable_object(binding()){d==d}, Predicate{ Eq(Color.new("purple"),
                                                                                Color.new("purple")) }
      assert Predicate.from_callable_object(binding()){d==d}.left === d
                                             
      assert_equal Predicate.from_callable_object(binding()){a==b && b==c}, 
                Predicate{ And(Eq(1,"1"),Eq("1","c")) }
    end
    
    
    test "parens change precedence" do
      assert_equal Predicate.from_callable_object{1==1 || 2==2 && 3==3}, 
        Predicate{ Or( Eq(1,1), And(Eq(2,2),Eq(3,3)) ) }
    
      assert_equal Predicate.from_callable_object{(1==1 || 2==2) && 3==3}, 
        Predicate{ And( Or(Eq(1,1),Eq(2,2)), Eq(3,3) ) }
    end
    
    test "works with procs and lambdas" do
      
      assert_equal Predicate.from_callable_object(proc{1<2}), Predicate{ Lt(1,2) }
      assert_equal Predicate.from_callable_object(lambda{1<2}), Predicate{ Lt(1,2) }
      
      a = "aaa"
      assert_equal Predicate.from_callable_object(proc{a=="bbb"}, binding()), 
        Predicate{ Eq("aaa","bbb") }
      assert_equal Predicate.from_callable_object(lambda{a=="bbb"}, binding()), 
        Predicate{ Eq("aaa","bbb") }
    end          

  end
  
  apropos "errors" do
    test "predicates only" do
      assert_raises(Predicated::Predicate::DontKnowWhatToDoWithThisSexpError) do 
        Predicate.from_callable_object{a=1}
      end
    end
  end
end