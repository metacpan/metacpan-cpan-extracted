#!perl -T
use strict;
use warnings;

use Test::More;

use lib ".";
use Tie::PagedArray;
$Tie::PagedArray::ELEMS_PER_PAGE = 3;

tie my(@tied_arr), 'Tie::PagedArray', page_size => 4, paging_dir => "/tmp";
push(@tied_arr, 10);
is @tied_arr, 1, "Length == 1";
@tied_arr = (11,12,13,14);
is @tied_arr, 4, "Length == 4 before push";
push(@tied_arr, 15);
is @tied_arr, 5, "Length == 5 after push";
is_deeply \@tied_arr, [11..15], "Contents 11..15";
#if ($] >= 5.012) {
#	print "Print with while(each) (>v5.012):\n";
#	while(my($i, $val) = each @tied_arr) {
#		print $val, "," ;
#	}
#}
#print "\n";
is_deeply [splice(@tied_arr, 2,2,10)], [13,14], "Spliced content test";
is $tied_arr[2],10, "Test inserted elem with splice";
print join(",", @tied_arr), "\n";

push(@tied_arr, 16);
print "SPLICED result:",join(",", splice(@tied_arr, 3,2,21)), "\n";
is(@tied_arr, 4, "size after splice==4");
print join(',', @tied_arr), "\n";

tie my(@car_parts), 'Tie::PagedArray', page_size => 2, paging_dir => "/tmp";
my $wheel = {name => "wheel", count => 4};
@car_parts = ($wheel, $wheel);
is($car_parts[0], $car_parts[1], "Two elements in same page point to same object 'before' page out");

$car_parts[2] = $wheel;
is($car_parts[0], $car_parts[1], "Two elements in same page point to same object 'after' page out");
isnt($car_parts[0], $car_parts[2], "Two elements in different pages do not point to same object");
done_testing();
#sleep(5);
exit 0;
