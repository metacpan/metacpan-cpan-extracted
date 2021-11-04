#!/usr/bin/perl
use strict; use warnings;

# vim=:SetNumberAndWidth

## Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl P.t'

#########################

use Test::More;

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

my $v;
ok($v=ErV($h, two), "ErV test h->{two}, existing?: true");
ok($v==2, "ErV test, returns value of two?");

ok(! ErV($h, four), "ErV test not exist(false)");

ok(! exists $h->{four}, "ErV testing last false didn't autovivify");

#test 15:
ok( ! (ErV($h, undef)), "ErV testing undef keyname(isfalse)");

ok( !defined( ErV ($h, undef)), "ErV testing undef is !defined");


my $h2;
ok (!defined (ErV ($h2, two)), "ErV test w/undef ref is !defined?");

ok(3 == (ErV ($h, three)), "ErV test that true = val of key");

## same tests with ErV

ok($v=(ErV ($h, two)), "ErV test existing->true?");
ok($v==2, "ErV test, returns value of two?");

ok(! (ErV ($h, four)), "ErV test not exist(false)");

ok(! exists $h->{four}, "ErV testing last false didn't autovivify");

#test 15:
ok( ! (ErV ($h, undef)), "ErV testing undef keyname(isfalse)");

ok( !defined( ErV ($h, undef)), "ErV testing undef is !defined");

#my $h2;
ok (!defined (ErV ($h2, two)), "ErV test w/undef ref is !defined?");

ok(3 == (ErV ($h, three)), "ErV test that true = val of key");


my $bh = bless $h, "myClass";
ok($v=ErV($bh, two), "ErV test bh->{two}, existing?: true");
ok($v==2, "ErV test, returns value of two?");

ok(! ErV($bh, four), "ErV test not exist(false)");

ok(! exists $bh->{four}, "ErV testing last false didn't autovivify");

ok( ! (ErV($bh, undef)), "ErV testing undef keyname(isfalse)");

ok( !defined( ErV ($bh, undef)), "ErV testing undef is !defined");


ok($v=ErV($bh, two), "ErV test bh->{two}, existing?: true");
ok($v==2, "ErV test, returns value of two?");

ok(! ErV($bh, four), "ErV test not exist(false)");

ok(! exists $bh->{four}, "ErV testing last false didn't autovivify");

ok( ! (ErV($bh, undef)), "ErV testing undef keyname(isfalse)");

ok( !defined( ErV ($bh, undef)), "ErV testing undef is !defined");

done_testing();

