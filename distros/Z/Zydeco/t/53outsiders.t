use strict;
use warnings;
use Test::More;

my $counter = 0;

package MyApp {
	use Zydeco;
	
	class Quux;
	
	method foo (Int $x) { 1000 + $x }
	
	multi method bar (ArrayRef $x) { 'ARRAY' }
	multi method bar (HashRef $y)  { 'HASH' }
	multi method bar (Quux $z)     { 'OBJECT' }
	
	before foo, bar { ++$counter }
	
	constant baz = 999;
	
	package MyApp::Other;
	method xyzzy { 666 }
}

is(MyApp->foo(-1), 999);
is(MyApp->foo(1000), 2000);

is(MyApp->bar([]), 'ARRAY');
is(MyApp->bar({}), 'HASH');
is(MyApp->bar(MyApp->new_quux), 'OBJECT');

is($counter, 5);

is(MyApp->baz, 999);

is(MyApp::Other->xyzzy, 666);

done_testing;
