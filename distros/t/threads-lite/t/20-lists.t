#!perl 

use Test::More tests=> 1;
use Test::Differences;

use threads::lite::list 'parallel_map';

alarm 5;

my @reference = map { $_ * 2} 1 .. 4;
{
	my @foo = parallel_map { $_ * 2 } undef, 1..4;

	eq_or_diff(\@foo, \@reference, "parallel_map { \$_ * 2 } 1..4");
}

