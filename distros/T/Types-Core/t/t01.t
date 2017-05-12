#!/usr/bin/perl
use strict; use warnings;

# vim=:SetNumberAndWidth

## Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl P.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

#########################


# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.


use Test::More tests => 3;

use Types::Core qw(! blessed);

my $a={};

ok(! blessed $a, "not bless test");

bless $a, "blessme";

ok(blessed $a, "blessed a test");

our $h = do { eval "HASH" };

	ok(!defined $h, "no HASH test");

