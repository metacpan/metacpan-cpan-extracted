#!/usr/bin/env perl
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Tie-NumericRange.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More qw(no_plan);

use lib ('../lib');

use Tie::NumericRange;

my %h;
tie (%h, Tie::NumericRange);

print "=== Object Tests ===\n\n";

is (ref(scalar(%h)), 'Tie::NumericRange', "Making sure scalar context works...");

print "\n=== Direct Assign Tests ===\n\n";

$h{100} = "Test";
is ($h{100}, 'Test', "Testing a direct hash assignment w/o range data...");

print "\n=== Integer Range Tests ===\n\n";

$h{'1..10,15,25..30'} = "Hi";
is ($h{3}, 'Hi', "Simple integer range lookups...");
is ($h{15}, 'Hi', "Simple integer single definition among range definition lookups...");
is ($h{14}, undef, "Attempt to look up non member...");
delete($h{'6..8'});
is ($h{7}, undef, "Attempt to look up range-deleted member...");
is ($h{5}, 'Hi', "Making sure the delete didn't disrupt other members...");

%h = ();
is ($h{5}, undef, "Making sure clear works...");

print "\n=== Floating Point Direct Assign Tests ===\n\n";

$h{'1.5'} = "Sup";

is($h{'1.5'}, 'Sup', "Testing floating point direct assign w/o range...");

$h{'2.66..4.89'} = "This";

is($h{'2.69'}, 'This', "Checking for in-range resolution at defined range precision...");
is($h{'2.681234567'}, 'This', "Checking for in-range resolution at a precision greater than defined range precision...");
is($h{'2.65'}, undef, "Attempt to look up non member...");
delete($h{'3.00'});
is($h{'3.00'}, undef, "Making sure a direct delete worked...");

$h{'6.100005..6.2'} = "big";

is($h{6.15}, 'big', "Testing a LARGE hash blow up...");

%h = ();

print "\n=== Hash Behavior Tests ===\n\n";

$h{'6..7'} = "Heya!";

is($h{6}, 'Heya!', "Sanity check for FETCH()...");
is(exists($h{6.17}), 1, "Making sure exists works...");
is(exists($h{3}), '', "Still making sure exists works...");
is(scalar(keys(%h)), 2, "keys()... what up on those?");

my ($k, $v) = each(%h);

is($k, '6', "each()... what up on thems?");
is($v, 'Heya!', "each()... is it real?");

# fin
