#!perl -w

use strict;
use Test::More tests => 28;

BEGIN{ $ENV{PERL_MACRO_DEBUG} ||= 1 } # using macro::filter

my @foo;
use macro
	mul   => sub{ $_[ 0 ] * $_[ 1 ] },
	sum   => sub{ my $sum = 0; for my $v(@_){ $sum += $v }; $sum },
	hello => q{"Hello!"},
	it    => sub{ $_ },
	foo   => sub{ @foo },
	mg0  => sub{ $![0] },
	num_of_arg => sub{ $#_ },
	my_or => sub{ $_[0] || $_[1] },
;

use 5.008_001;

is mul(2,2), 4, 'normal';
is mul ( 2 , 2 ), 4, 'with white spaces';
is mul
(2,
		2
), 4, 'with newlines';

is mul(1+1, 1+1), 4, 'expr';
is mul(3 => 4),  12, '=>';
is mul(2, 3, ),   6, 'an extra comma';

my $var = 10;
is mul($var, $var), 100, 'variable';
is mul( mul(3, 4), mul(5, 6) ), 360, 'deep calls';
is mul( mul( mul(2, mul(2, 2)), 2 ), mul(2, 2) ), 64, 'more deep calls';

is q{mul(1, 2)}, 'm' . 'ul(1, 2)', q{doesn't touch string literals};

is sum(1, 2, 3), 6, '@_ == (1, 2, 3)';
is sum(),    0, '@_ == ()';
is sum( sum(1, 2, 3), sum(4, 5, 6) ), 21, 'multicall with @_';

is hello(), 'Hello!', 'without arguments';
my %hash = ('Hello!' => 'A', 'hello' => 'B');
is $hash{hello()}, 'A', 'hash subscript';
is $hash{hello},   'B', 'hash subscript';

$_ = 42;
is it(), 42, '$_ is not replaced';

@foo = (43, 44);
is_deeply [foo()], [43, 44], '@foo is not replaced';

@! = ('!0');
is_deeply [mg0()], ['!0'],    '$![0] is not replaced';

is num_of_arg(),  -1, 'ArrayIndex';
is num_of_arg(0), 0, 'ArrayIndex';
is num_of_arg(1, 2, 3), 2, 'ArrayIndex';
is num_of_arg(1,2,3,4,), 4, 'ArrayIndex';

is my_or(0, 42), 42, 'or in macro(1)';
is my_or(42, 2), 42, 'or in macro(2)';

sub mul(){
	'foo';
}

is mul, 'foo', 'bareword (not replaced)';
is &mul(1, 2), 'foo', '&funcall (not replaced)';

sub Foo::mul{
	'bar';
}

is( Foo->mul(), 'bar', 'method call (not replaced)' );

