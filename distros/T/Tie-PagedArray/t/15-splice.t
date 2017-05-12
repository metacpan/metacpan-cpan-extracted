#!perl -T

use lib ".";
use Test::More tests=>19;
my ($passes, $fails) = (0,0);
use_ok('Tie::PagedArray') && ++$passes || ++$fails;
$" = ",";
my $page_size = 5;
tie my(@arr), 'Tie::PagedArray', page_size => $page_size;
is(tied(@arr)->[2], 5, "Test page size==$page_size") && ++$passes || ++$fails;

print "Insert within 1st page\n";
@arr = (11..13);
is_deeply(\@arr, [11..13], "Initialize with 3 elements") && ++$passes || ++$fails;
my @res = splice(@arr, 1, 0, 101);
is(@arr, 4, "Test size==4") && ++$passes || ++$fails;
is_deeply(\@arr, [11,101,12,13], "Test contents") && ++$passes || ++$fails;
#$#arr = -1;

@res = splice(@arr, 1, 0, 102);
is(@arr, 5, "Test size==5") && ++$passes || ++$fails;
is_deeply(\@arr, [11,102,101,12,13], "Test contents") && ++$passes || ++$fails;

@arr=(11..13);
@res = splice(@arr, 1, 0, 101,102);
is(@arr, 5, "Test size==5") && ++$passes || ++$fails;
is_deeply(\@arr, [11,101,102,12,13], "Test contents") && ++$passes || ++$fails;

@arr=(11..13);
@res = splice(@arr, 0, 1, 101,102,103);
is(@arr, 5, "Test size==5") && ++$passes || ++$fails;
is_deeply(\@arr, [101,102,103,12,13], "Test contents") && ++$passes || ++$fails;

print "Insert into a 2 page array!!!\n";
@res = splice(@arr, 2, 0, 201, 202);
is(@arr, 7, "Test size==7") && ++$passes || ++$fails;
is_deeply(\@arr, [101,102,201,202,103,12,13], "Test contents") && ++$passes || ++$fails;

@arr = (11..15);
@res = splice(@arr, 2, 0, 101..105);
is(@arr, 10, "Test size==10") && ++$passes || ++$fails;
is_deeply(\@arr, [11,12,101..105,13,14,15], "Test contents") && ++$passes || ++$fails;

@arr = (11..15);
@res = splice(@arr, 2, 0, 101..121);
is(@arr, 26, "Test size==26") && ++$passes || ++$fails;
is_deeply(\@arr, [11,12,101..121,13,14,15], "Test contents") && ++$passes || ++$fails;

@arr = (11..20);
@res = splice(@arr, 4, 1);
@res = splice(@arr, 4, 0, 101);
is(@arr, 10, "Test size==10") && ++$passes || ++$fails;
is_deeply(\@arr, [11..14,101,16..20], "Test contents") && ++$passes || ++$fails;

print "Tests passed = $passes of ", ($passes + $fails), "\n";
