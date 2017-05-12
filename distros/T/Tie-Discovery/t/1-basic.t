# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl t/1-basic.pl'

######################### We start with some black magic to print on failure.

BEGIN { $| = 1; print "1..9\n"; }
END { print "not ok 1\n" unless $loaded; }

use Tie::Discovery;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

my %test;
my $obj = tie %test, "Tie::Discovery" or print "not ";
print "ok 2\n";

$obj->store('debug', 2);
print "ok 3\n";

print "not " if $test{debug} != 2;
$obj->store('debug', 0);
print "ok 4\n";

$obj->register("one", sub { 1 });
print "not " if $test{one} != 1;
print "ok 5\n";
$obj->register("two",   sub { $test{one} + 1 });
$obj->register("three", sub { $test{two} + 1 });
$obj->register("four",  sub { $test{three} + $test{one} });

print "not " if $test{four} != 4;
print "ok 6\n";

eval { $obj->register("one", 1) };
print "not" unless $@;
print "ok 7\n";

$obj->register(
    "five",
    sub { sub { sub { 5 } } }
);
print "not " if $test{five} != 5;
print "ok 8\n";

$obj->register(
    "six",
    sub { $_[0]->FETCH('three') * $_[0]->FETCH('two') }
);
print "not " if $test{six} != 6;
print "ok 9\n";
