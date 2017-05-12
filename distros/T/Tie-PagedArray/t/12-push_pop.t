#!perl -T

use lib ".";
use Test::More tests => 102;
use_ok('Tie::PagedArray');
my $page_size = 5;
tie my(@arr), 'Tie::PagedArray', page_size => $page_size;
is(tied(@arr)->[2], 5, "Test page size==$page_size");
my @normal_arr;
$" = ",";

my $test_val = 11;
my $last_val = 30;

print "==> Testing Push\n";
my $test_len = 1;
for($test_val..$last_val) {
	my $len = push @arr, [1, {number => $_}];
	push @normal_arr, [1, {number => $_}];
	is($len, $test_len, "Test size returned by push==$test_len");
	is(@arr, $test_len, "Test actual size==$test_len");
	is_deeply(\@arr, \@normal_arr, "Test contents of array");
	$test_len++;
}

print "==> Testing Pop\n";
while(@normal_arr) {
	my $test_val = pop(@normal_arr);
	is_deeply(pop(@arr), $test_val, "Test return value");
	is_deeply(\@arr, \@normal_arr, "Test remaining content");
}
