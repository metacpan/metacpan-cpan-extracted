# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

print "1..6\n";

my $i = 1;

use Uniq;
use strict;

# Does it change a proper list? (It should not)
# Does it drop duplicates from list? ( It should)

my @ out = uniq sort 1,2,3,4,5,6,7;
print "not " if (  "@out" ne "1 2 3 4 5 6 7" );
printf "ok %d\n", $i++;

@ out = uniq sort 1,2,2,3,4,5,6,7,7;
print "not " if (  "@out" ne "1 2 3 4 5 6 7" );
printf "ok %d\n", $i++;

@ out = uniq sort "A1","A2","A3","A4","A5","A6","A7";
print "not " if (  "@out" ne "A1 A2 A3 A4 A5 A6 A7" );
printf "ok %d\n", $i++;

@ out = uniq sort "A1","A2","A2","A3","A4","A5","A6","A7","A7";
print "not " if (  "@out" ne "A1 A2 A3 A4 A5 A6 A7" );
printf "ok %d\n", $i++;

@ out = distinct sort "A1","A2","A2","A3","A4","A5","A6","A7","A7";
print "not " if (  "@out" ne "A1 A3 A4 A5 A6" );
printf "ok %d\n", $i++;

@ out = dups sort "A1","A2","A2","A3","A4","A5","A6","A7","A7";
print "not " if (  "@out" ne "A2 A7" );
printf "ok %d\n", $i++;

