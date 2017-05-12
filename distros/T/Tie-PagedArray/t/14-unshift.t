#!perl -T

use lib ".";
use Test::More tests=>322;
use_ok('Tie::PagedArray');
my $page_size = 5;
tie my(@arr), 'Tie::PagedArray', page_size => $page_size;
is(tied(@arr)->[2], 5, "Test page size==$page_size");
my @normal_arr;
$" = ",";

my $test_val = 11;
my $last_val = 30;

my $ec = 1;
for (my $ec = 0; $ec <= 7; $ec++) {
	print "===> Unshift $ec elements at a time\n";
	my $i = 1;
	for($test_val..$last_val) {
		my $len = unshift @arr, map { [$ec, {number => $_}] } ($_..$_+$ec);
		unshift @normal_arr, map { [$ec, {number => $_}] } ($_..$_+$ec);
		is($len, scalar(@normal_arr), "Test len==".scalar(@normal_arr));
		is_deeply(\@arr, \@normal_arr, "Test contents of array");
		$i++;
	}
}
