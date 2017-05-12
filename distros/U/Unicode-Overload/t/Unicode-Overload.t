# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Unicode-Overload.t'

#########################

use Test::More tests => 14;
#BEGIN { use_ok('Unicode::Overload') };

#########################

use utf8;
use charnames ':full';
use POSIX;

use Unicode::Overload
	(
	"\N{N-ARY SUMMATION}" => prefix => sub # U+2211
		{
		my $sum=shift;$sum+=$_ for @_;$sum
		},
	"\N{ELEMENT OF}" => infix => sub # U+2208
		{
		my $elem=shift;return grep($_==$elem,@_)>0
		},
	"\N{SUPERSCRIPT TWO}" => postfix => sub # U+00B2
		{
		$_[0]*$_[0]
		},
	[ "\N{LEFT FLOOR}", "\N{RIGHT FLOOR}" ] => outfix => sub # U+230A,U+230B
		{
		POSIX::floor($_[0])
		},
	);
ok(∑(1,2,3,4) == 10, "Sigma failed");
ok((2)² == 4, "Square failed");
ok((1∈(1,2,3)), "Element failed");
ok( ⌊-23.4⌋ == -24, "Floor failed");

ok(∑ (1,2,3,4) == 10, "Sigma with trailing space failed");
ok((2) ² == 4, "Square with leading space failed");
ok((1 ∈(1,2,3)), "Element with leading space failed");
ok((1∈ (1,2,3)), "Element with trailing space failed");
ok( ⌊ -23.4⌋ == -24, "Floor with leading space failed");
ok( ⌊-23.4 ⌋ == -24, "Floor with trailing space failed");

my @a = (1,2,3,4);
  ok(∑ (@a) == 10, "Sigma with variable and trailing space failed");
my $b = 2;
  ok(($b) ² == 4, "Square with leading space failed");
my $elem = 2; my @list = (1,2,3);
  ok(($elem ∈@list), "Element with variable and leading space failed");
my $c = -23.4;
  ok( ⌊$c⌋ == -24, "Floor with trailing space failed");
