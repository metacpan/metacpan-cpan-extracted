#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 21;

my $m;
BEGIN { use_ok($m = "Test::TAP::Model::Subtest") }

isa_ok(my $s = $m->new(my $r = {
	type => "test",
	num => 7,
	ok => 1,
	actual_ok => 0,
	todo => 0,
	skip => 0,
	reason => "foo",
	line => "this is a line",
	diag => "diagnosis",
	pos => "foo at line 4, column 3",
	str => "stringified",
}), $m);

ok($s->ok, "ok");
ok(!$s->actual_ok, "actual_ok");
ok(!$s->nok, "failed");
ok(!$s->skipped, "skipped");
ok(!$s->todo, "todo");

is($s->num, 7, "number");
is($s->line, "this is a line", "line");
is($s->diag, "diagnosis", "line");
is($s->reason, "foo", "reason");
is($s->pos, "foo at line 4, column 3", "pos");

is($s->test_file, "foo", "pos hack file");
is($s->test_line, 4, "pos hack line");
is($s->test_column, 3, "pos hack col");

$r->{$_} = !$r->{$_} for qw/ok actual_ok skip todo/;

ok(!$s->passed, "ok");
ok($s->actual_ok, "actual_ok");
ok($s->failed, "failed");
ok($s->skipped, "skipped");
ok($s->todo, "todo");

is("$s", "stringified", "stringification");

