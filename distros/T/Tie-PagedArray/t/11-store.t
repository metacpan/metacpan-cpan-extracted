#!perl -T

use lib ".";
use Test::More tests => 1408;
use_ok('Tie::PagedArray');
my $page_size = 5;
tie my(@arr), 'Tie::PagedArray', page_size => $page_size;
is(tied(@arr)->[2], 5, "Test page size==$page_size");
$" = ",";

print "==> Store lists\n";

for my $i (0..25) {
	my $e = 11+$i;
	@arr = map { [$e, {number => $_}] } (11..11+$i);
	my $test_len = $i+1;
	is(@arr, $test_len, "Test size==$test_len");
	is_deeply(\@arr, [map { [$e, {number => $_}] } 11..$e], "Test content");
}
$#arr = -1;
is(@arr, 0, "Emptied the array. Test size==0");
is_deeply(\@arr, [], "Emptied the array. Test contents");

print "==> Sparse arrays with only 1 element\n";
foreach my $i (0..25) {
	$arr[$i] = [$i, {number => 11}];
	my $test_len = $i+1;
	is(@arr, $test_len, "Test size==$test_len. Populated position $i");
	is_deeply(\@arr, [map({undef} 1..$i), [$i, {number => 11}]], "Test content ");
	$#arr = -1;
}

print "==> Sparse arrays with several elements at different distances\n";
for my $spacing (1..25) {
	foreach my $i (0..25) {
		$arr[$i] = 11;
		$arr[$i+$spacing] = 12;

		is(@arr, $i+$spacing+1, "Test size==".($i+$spacing+1).". Populated positions $i,".($i+$spacing));
		is_deeply(\@arr, [map({undef} 1..$i), 11, map({undef} $i+1..$i+$spacing-1), 12], "Test content");
		$#arr = -1;
	}
}
