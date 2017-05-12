use strict;
use warnings;

use Test::More tests => 15;

use Scalar::Util qw( refaddr );

my $CLASS = 'Tree';
use_ok( $CLASS )
    or Test::More->builder->BAILOUT( "Cannot load $CLASS" );

# Test plan:
# 1) The null object should inherit from Tree::Simple
# 2) It should be false in all respects
# 3) It should report that it can perform any method
# 4) Any method call on it should return back the null object

my $NULL_CLASS = $CLASS . '::Null';

my $obj = $NULL_CLASS->new;
isa_ok( $obj, $NULL_CLASS );
isa_ok( $obj, $CLASS );

ok( !$obj->isa( 'Floober' ), "Verify that isa() works in the negative case" );

TODO: {
    local $TODO = "Need to figure out a way to have an object evaluate as undef";
    ok( !defined $obj, " ... and undefined" );
}
ok( !$obj, "The null object is false" );
ok( $obj eq "", " .. and stringifies to the empty string" );
ok( $obj == 0, " ... and numifies to zero" );

can_ok( $obj, 'some_random_method' );
my $val = $obj->some_random_method;
is( refaddr($val), refaddr($obj), "The return value of any method call on the null object is the null object" );

my $subref = $obj->can( 'some_random_method' );
my $val2 = $subref->($obj);
is( refaddr($val2), refaddr($obj), "The return value of any method call on the null object is the null object" );

is( refaddr($obj->method1->method2), refaddr($obj), "Method chaining works" );

is( refaddr($CLASS->_null), refaddr($obj), "The _null method on $CLASS returns a null object" );
my $tree = $CLASS->new;
isa_ok( $tree, $CLASS );
is( refaddr($tree->_null), refaddr($obj), "The _null method on an object of $CLASS returns a null object" );
