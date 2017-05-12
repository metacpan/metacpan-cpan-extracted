#!perl -T

use strict;
use warnings FATAL => 'all';
use Test::More tests => 20;
use Variable::Lazy;

my $num = 1;

lazy my $x = { $num++ };

is($num, 1, '$num == 1');
is($x,   1, '$x   == 1');
is($num, 2, '$num == 2');
is($x,   1, '$x   == 1');

is(lazy { $num }, $num, 'lazy $num = $num');


sub foo {
	is($num, 2, '$num == 2');
	my $arg = shift;
	is($num, 3, '$num == 3');
	is($arg, 2, '$arg == 2');
}

foo(lazy { $num++ } );

lazy $x = { --$num };

is($num, 3, '$num == 3');
is($x,   2, '$x   == 2');
is($num, 2, '$num == 2');
is($x,   2, '$x   == 2');

lazy my $y = { ++$num };

$y = 0;

is($num, 2, '$num == 3');
is($y,   0, '$y   == 2');
is($num, 2, '$num == 3');


my $reference = $num;

sub bar {
	my $argument = $_[0];
	lazy my $first = { $argument++ };
	is($_[0], $reference, '$_[0] == $reference');
	is($argument, $reference, '$argument == $reference + 1');
	is($first, $reference, '$first == $reference');
	is($argument, $reference + 1, '$argument == $reference + 1');

	TODO: {
		local $TODO = "Arguments values are still buggy";
		lazy my $second = { $_[0]++ };
		is($second, $_[0], '$second == $_[0]');
		return $second;
	}
}

my $ret = bar($num);
