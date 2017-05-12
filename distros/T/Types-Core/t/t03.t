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


use Test::More tests => 5;

use Types::Core;

sub Asub () { 0x11223344 }

my $a = sub () { print "Asub" };
my $b = \&Asub;

ok((CODE $a), "\$a ref to anonsub");
ok((CODE $b), "\$b ref to Asub");
ok((CODE \&Asub), "CODE Asub test");

our @ar=(1,2,3);
our $ar1 = \@ar;
our $ar2 = \$ar1;

ok((REF $ar2), "REF of \\[1,2,3]");

our $ar3=${REF $ar2};

ok((ARRAY $ar3), "deref REF (\${\\[1,2,3]} => ARRAY([1,2,3])");
