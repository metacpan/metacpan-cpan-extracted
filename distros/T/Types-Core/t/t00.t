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


use Test::More tests => 18;

use_ok('Types::Core');
use Types::Core;

my @test_types=qw(HASH ARRAY SCALAR CODE GLOB REF);

my @refs = ({}, [], \$_, sub(){});

my $i;
for($i=0;$i<@refs;++$i) {
	my $ref = ref $refs[$i];
	my $typ = $test_types[$i];

	ok($ref eq $typ, "test ".$typ);
}

my @test_strings = (HASH, ARRAY, SCALAR, CODE, GLOB, REF);
for ($i=0; $i<@refs;++$i) {
	my $ref = ref $refs[$i];
	my $typ = $test_strings[$i];
	ok($ref eq $typ, "test lit ".$typ);
}

use Types::Core qw(blessed);

my $a={};

ok(! blessed $a, "not bless test");

bless $a, "blessme";

ok(blessed $a, "blessed a test");

my $h={one=>1, two=>2, three=>3};

ok((EhV $h, two), "EhV test existing->true?");

ok(! (EhV $h, four), "EhV test not exist(false)");

ok(! exists $h->{four}, "EhV testing last false didn't autovivify");

#test 15:
ok( ! (EhV $h, undef), "EhV testing undef keyname(isfalse)");

ok( !defined( EhV $h, undef), "EhV testing undef is !defined");

my $h2;
ok (!defined (EhV $h2, two), "EhV test w/undef ref is !defined?");

ok(3 == (EhV $h, three), "Ehv test that true = val of key");



