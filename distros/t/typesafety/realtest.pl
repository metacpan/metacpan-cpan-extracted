#
# test class 
#

# see test.pl for an explanation of this file and how it is used to trip all of typesafety.pm's triggers
# this file details all (or almost all) of the constructs that are valid under typesafety.pm.
# it also details examples of constructs that are illegal and cause typesafety.pm to emit a diagnostic.

package FooBar;
use lib '.';
use typesafety;

# proto 'new', returns => 'FooBar';

sub new {
  my $type = shift; $type = ref $type if ref $type;
  bless [], 'FooBar'; 
  # bless [], $type;
}

# proto 'foo', returns => 'FooBar', takes => 'FooBar', undef, 'FooBar', 'BazQux', undef, undef, undef;

sub foo (FooBar; FooBar, undef, FooBar, BazQux, undef, undef, undef) {
  # my $me = shift;   
  return BazQux->new(); # works - BaxQux isa FooBar
  # return WrongType->new(); # illegal - sub foo is prototyped to return a FooBar
  # return $me->new(); # unable to solve type
}

proto 'yutz', returns => 'BazQux';

sub yutz { return BazQux->new(); }
# sub yutz { return WrongType->wrong(); }

proto 'yadda', returns => 'FooBar';

# sub yadda { $_[0]->new(); } # unrecognized construct
sub yadda { FooBar->new(); }

#
# test class 
#

package BazQux;
use typesafety;
@ISA = qw(FooBar);

proto 'new', returns => 'BazQux';

sub new {

  # this idiom should be supported...
  my $type = shift; $type = ref $type if ref $type;
  bless [], $type;
  
  # testing support for this one - works
  # bless [], $_[0];

}

# wrong array type :  type mismatch: expected:  
# prototyped method new, type BazQux, defined in package BazQux, file realtest.pl, line 45 ; 
# got:  
# construct doesn't return any value that we know of unrecognized construct (op: gv) ?, type none, defined in package ?, file ?, line ?  
# in package BazQux, file realtest.pl, line 48 at typesafety.pm line 1177.


#
# test class
#

package WrongType;
use typesafety;

sub new {
  my $type = shift;   # whooa! this works too now! bing, bing, bing =)
  bless [], $type;
}

proto 'wrong', returns => 'WrongType';

sub wrong { $_[0] }

#
#
#

package main;
use typesafety; # 'debug';

#
# basic declarations
#

my FooBar $foo; $foo = new FooBar;
my FooBar $bar; $bar = new FooBar;
my BazQux $baz; $baz = new BazQux;

# my Foo::Bar $bar;  # seems to work, given a Foo::Bar package

#
# two declarations on the same line. this used to be a problem in an early early version =)
#

my FooBar $test1; my FooBar $test2;


#
# basic assignments
#

my $blurgh;
# $bar = $blurgh;  # illegal - $bar is typed, it cannot hold untyped $blurgh
# $bar = 1;        # illegal - $bar is typed, it cannot hold the constant 1

$foo = $bar;       # okey - simple assignment

#
# assigning to declarations
#

# my FooBar $test6 = 1;          # illegal - cannot assign constant 1 to $test6

$foo = new BazQux (1,2,3,4);     # yes - correct - BazQux isa FooBar, foo holds FooBars

# array used inconsistently :  type mismatch: expected:  
# prototyped method new, type BazQux, defined in package BazQux, file realtest.pl, line 50 ;
# got:  
# constructor new, type FooBar, defined in package FooBar, file realtest.pl, line 84  in package main, file realtest.pl, line 115 
# at typesafety.pm line 1111.

# $baz = $foo->foo(1,2,3,4);     # illegal - prototyped
if(0) { $foo->doesntexist(); }   # illegal - unknown method - XXX - this shouldn't work - why does it? if().
# $foo = $foo->foo();
# $foo = $foo->doesntexist();    # xxillegal, but by perl, not by us - doesn't get that far

#
# prototypes
#

$bar = $foo->foo($foo, 1, $bar, $baz, 2, 3, lala());              # this works
$bar = $foo->foo($foo, $foo, $bar, $baz, $baz, 3, lala());        # this works too
$bar = $foo->foo($foo->yadda(), 1, $bar, $baz, $baz, 3, lala());  # this should work, but does it? awesome!
$bar = $foo->foo($foo->yutz(), 1, $bar, $baz, $baz, 3, lala());   # this works - BazQux isa FooBar

my $wrongtype = new WrongType;

# $bar = $foo->foo(WrongType->new(), 1, $bar, $baz, $baz, 3, lala());   # illegal - arguments don't match prototype
# $bar = $foo->foo($wrongtype->wrong(), 1, $bar, $baz, $baz, 3, lala());   # illegal - arguments don't match prototype
# $bar = $foo->foo(1, 1, $bar, $bar, 2, 3, lala());                 # illegal - argument don't match prototype

sub lala { return 3+rand(5); }

#
# misc
#

# $foo = new FooBar 1, 2, 3, 4, 5, 6;

#
# inheritance
#

# $baz = $foo->new();  # illegal - BazQux $baz is a subclass of FooBar $foo
$foo = $baz;           # allowed - $baz is a $foo

#
# array type inferance
#

my @arr1;
push @arr1, $foo; # a FooBar
push @arr1, $baz; # inherits FooBar
my WrongType $wt2;
# $wt2 = $arr1[0]; # illegal - @arr1 will consider itself to be of type FooBar at this point, incompatable with WrongType

#
# hash type inferance
#

my %hash1;
my %hash2;

$hash1{foo} = new FooBar;
$hash2{foo} = new WrongType;

# $hash1{foo} = $hash2{foo}; # illegal - cannot assign WrongType to FooBar - woo, works!

# %hash1 = %hash2; # illegal - same reason

#
# and, go!
#

typesafety::check();


