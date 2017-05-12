#!/usr/bin/perl
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

use strict;
use warnings;
use Test::Simple tests => 2;
use ExtUtils::MakeMaker qw(prompt);

my $NUM_TESTS = 2;

use Win32::LockWorkStation;
ok(1, "Loading Module"); # If we made it this far, we're ok.

#########################

print <<STOP;

  Win32::LockWorkStation needs a user to interact with to 
  perform the full set of tests.  If you want to continue, 
  this test will lock your workstation and you will be 
  expected to unlock it (providing your password).

  To continue without running the tests (if perhaps you  
  don't want to or aren't a sentient human or alien that 
  understands English), simply press 'Enter'.


STOP

my $continue = prompt("Continue with tests? ('y' and 'Enter')  : ", '');

if ($continue eq '') {
    for (2..$NUM_TESTS) {
        ok(1, "Skipping test ...")
    }
    exit
}

print "\n";
#########################

if (defined(Win32::LockWorkStation->LockWorkStation())) {
    ok(1, "Locking Workstation")
} else {
    ok(0, "Locking Workstation")
}
