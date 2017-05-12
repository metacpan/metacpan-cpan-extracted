#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 22;

use lib "t/lib";
use StringHarness;

my $m; BEGIN { use_ok($m = "Test::TAP::Model::Consolidated") }

my $normal = "Test::TAP::Model";

{
	my $s1 = strap_this($normal, one => <<TAP);
1..2
ok 1
ok 2
TAP
	my $s2 = strap_this($normal, two => <<TAP);
1..2
ok 1
ok 2
TAP

	isa_ok(my $c = $m->new($s1, $s2), $m);
	ok($c->ok, "both tests are OK");
	is($c->test_files, 1, "one test file within");
	my $f = ($c->test_files)[0];
	is($f->ok_tests, 4, "4 passing subtests");
	is($f->cases, 4, "4 subtests altogether");
	is($f->ratio, 1, "ok/nok ratio is 1:1");
	ok($f->consistent, "composite file is consistent");
}

{
	my $s1 = strap_this($normal, one => <<TAP);
1..2
ok 1
not ok 2
TAP
	my $s2 = strap_this($normal, two => <<TAP);
1..2
ok 1
ok 2
TAP
	my $c = $m->new($s1, $s2);
	ok(!$c->ok, "both tests not OK together");
	my $f = ($c->test_files)[0];
	is($f->ok_tests, 3, "3 passing subtests");
	is($f->cases, 4, "4 subtests altogether");
	is($f->ratio, 3/4, "ok/nok ratio is 3:4");
	ok(!$f->consistent, "composite file is not consistent");

	is($f->subfiles, 2, "composite file has 2 subfiles");
	my @sub = $f->subfiles;
	is($sub[0]->cases, 2, "two cases in first");
	is($sub[0]->ratio, 1/2, "50% success in first");
	is($sub[1]->cases, 2, "two cases in second");
	is($sub[1]->ratio, 1, "100% success in first");

	my @fcases = $sub[0]->cases;
	ok($fcases[0]->ok, "first subcase of first is OK");
	ok($fcases[1]->nok, "second subcase of first is not OK");

	my @scases = $sub[1]->cases;
	ok($scases[0]->ok, "first subcase of second is OK");
	ok($scases[1]->ok, "second subcase of second is OK");
}
