#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 15;
use Test::Harness::Results;

my $m;

BEGIN { use_ok($m = "Test::TAP::Model::File::Visual") }

isa_ok((bless {}, $m), "Test::TAP::Model::Colorful");
isa_ok((bless {}, $m), "Test::TAP::Model::File");

can_ok($m, "subtest_class");
like($m->subtest_class, qr/::Visual$/, "it's visual");

can_ok($m, "link");
can_ok($m, "case_rows");

can_ok($m, "str_status");

my $f = $m->new(my $r = {
	file => "foo",
});

my $results = Test::Harness::Results->new();
$r->{results} = $results;
$results->inc_max();
$results->set_passing( 1 );
$results->inc_seen();
is($f->str_status, "OK", "seen + ok = OK");

$results->inc_max();
is($f->str_status, "FAILED", "seen != planned = FAILED");

$r->{results} = $results = Test::Harness::Results->new();
$results->inc_max();
is($f->str_status, "FAILED", "no tests + ok = FAILED");

$results->inc_seen();
is($f->str_status, "FAILED", "seen + fail = FAILED");

$results->set_passing( 1 );
$r->{events}[0]{type} = "bailout";
is($f->str_status, "BAILED OUT", "seen + ok + bailout = BAILED OUT");

$results->set_skip_all( "foo" );
$r->{events} = [];
is($f->str_status, "SKIPPED", "seen + ok + skip_all = SKIPPED");

$r->{results} = $results = Test::Harness::Results->new();
$results->set_skip_all( "foo" );
is($f->str_status, "SKIPPED", "no seen + ok + skip_all = SKIPPED");
