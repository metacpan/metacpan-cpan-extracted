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

my $scalar=1;
my $array=[];
my $undef=undef;


ok((!ARRAY $scalar), "scalar ! ARRAY");

ok((ARRAY $array), "ARRAY array?");
ok($array eq (ARRAY $array), "array eq ARRAY array?");
ok(!(ARRAY $undef), "!ARRAY undef?");
ok (ARRAY eq 'ARRAY', "bareword eq quoted?");

