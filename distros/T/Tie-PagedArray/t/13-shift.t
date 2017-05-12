#!perl -T

use lib ".";
use Test::More tests => 64;
use_ok('Tie::PagedArray');
my $page_size = 5;
tie my(@arr), 'Tie::PagedArray', page_size => $page_size;
is(tied(@arr)->[2], 5, "Test page size==$page_size");
$" = ",";

my $test_val = 11;
my $last_val = 30;
@arr = map { [42, {number => $_}] } ($test_val..$last_val);
is(@arr, ($last_val - $test_val + 1), "Test size after initialization==".($last_val - $test_val + 1));
is_deeply(\@arr, [map { [42, {number => $_}] } $test_val..$last_val], "Test content after initialization");

while(@arr) {
	my $val = shift @arr;
	is_deeply($val, [42, {number => $test_val}], "Test value==$test_val");
	my $test_len = 30-$test_val;
	is(@arr, $test_len, "Test size==$test_len");
	$test_val++;
	is_deeply(\@arr, [map { [42, {number => $_}] } $test_val..$last_val], "Test contents of array");
}
