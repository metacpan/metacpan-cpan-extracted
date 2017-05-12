use strict;
use warnings FATAL => 'all';
use Test::More qw(no_plan);
use Scalar::Util qw(weaken);
use curry;

{
  package Foo;

  sub new { bless({}, shift) }

  sub foo { [@_] }
}

my $foo = Foo->new;

is_deeply($foo->foo(1), [ $foo, 1 ], 'Direct object call');
is_deeply($foo->curry::foo->(1), [ $foo, 1 ], 'Curried object call');

weaken(my $weak_foo = $foo);

my $curry = $foo->curry::foo;

undef($foo);

ok($weak_foo, 'Weakened object kept alive by curry');

undef($curry);

ok(!$weak_foo, 'Weakened object dead');

$foo = Foo->new;

$curry = $foo->curry::weak::foo;

is_deeply($curry->(1), [ $foo, 1 ], 'Curried weak object call');

weaken($weak_foo = $foo);

undef($foo);

ok(!$weak_foo, 'Weak curry does not keep object alive');

is($curry->(1), undef, 'Weak curry returns undef after object is dead');
