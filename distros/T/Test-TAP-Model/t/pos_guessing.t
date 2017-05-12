#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 12;

my $m;
BEGIN { use_ok($m = "Test::TAP::Model") }

isa_ok(my $s = $m->new, $m);

my $f = $s->start_file("foo");
eval { $f->{results} = $s->analyze("foo", [split /\n/, <<TAP]) };
1..3
ok 1 foo <pos:foo.t at line 2, column 1>
ok 2 foo <pos:file "gorch" line 4>
ok 3 foo <pos:file bar, column 5, line 6>
TAP

ok($s->ok, "suite passed");

my @files = $s->test_files;

my @cases = $files[0]->test_cases;

is($cases[0]->test_file, "foo.t", "file of 1");
is($cases[0]->test_line, 2, "line of 1");
is($cases[0]->test_column, 1, "col of 1");

{ local $TODO = "use Regexp::Common quoted parsing";
	is($cases[1]->test_file, "gorch.t", "file of 2");
}
is($cases[1]->test_line, 4, "line of 2");
ok(!$cases[1]->test_column, "no clumn");

is($cases[2]->test_file, "bar", "file of 3");
is($cases[2]->test_line, 6, "line of 1");
is($cases[2]->test_column, 5, "col of 1");

