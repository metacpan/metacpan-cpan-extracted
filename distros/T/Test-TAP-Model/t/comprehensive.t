#!/usr/bin/perl

use Test::More tests => 122;

use strict;
use warnings;

use List::Util qw/sum/;

use lib "t/lib";
use StringHarness;

my $m;
BEGIN { use_ok($m = "Test::TAP::Model") };

sub c_is (&$$){ # like Test::More::is, but in two contexts
	my $code = shift;
	my $exp = shift;
	my $desc = shift;

	my @list = &$code;
	my $scalar = &$code;

	is(@list, $exp, $desc . " in list context");
	is($scalar, $exp, $desc . " in scalar context");
}

{
	my $s = strap_this($m, skip_some => <<TAP);
1..2
ok 1 foo # skip cause i said so
ok 2 bar
TAP

	ok($s->ok, "suite OK");
	
	is($s->test_files, 1, "one file");
	isa_ok(my $f = ($s->test_files)[0], "Test::TAP::Model::File");

	ok($f->ok, "file is ok");
	ok(!$f->bailed_out, "file did not bail out");

	is($f->pre_diag, "", "no pre diag");

	is(my @cases = $f->cases, 2, "two subtests");
	ok($cases[0]->ok, "1 ok");
	ok($cases[0]->skipped, "1 skip");
	is($cases[0]->reason, "cause i said so", "reason");
	ok($cases[1]->ok, "2 ok");
	ok(!$cases[1]->skipped, "2 not skip");
}

{
	my $s = strap_this($m, bail_out => <<TAP);
1..2
ok 1 foo
Bail out!
TAP

	is($s->test_files, 1, "one file");
	isa_ok(my $f = ($s->test_files)[0], "Test::TAP::Model::File");

	is(my @cases = $f->subtests, 2, "missing subtests after bailout are stubbed");

	ok(!$s->ok, "whole run is not ok");
	ok(!$f->ok, "file is not ok");
	ok($f->bailed_out, "file bailed out");
	ok($cases[0]->ok, "first case is ok");
	ok(!$cases[1]->ok, "but not second");

	is($f->actual_cases, 1, "1 test, actually");
	is_deeply([ $f->actual_cases ], [ $cases[0] ], "no stubs");
}

{
	my $s = strap_this($m, todo_tests => <<TAP);
1..4
ok 1 foo
not ok 2 bar
not ok 3 gorch # TODO burp
ok 4 baz # TODO bzzt
TAP

	is($s->test_files, 1, "one file");
	isa_ok(my $f = ($s->test_files)[0], "Test::TAP::Model::File");
	
	is($f->cases, 4, "actual cases");
	is($f->planned, 4, "number planned");
	ok($f->nok, "file as a whole is not ok");

	my @cases = $f->cases;

	isa_ok($cases[0], "Test::TAP::Model::Subtest");
	ok($cases[0]->ok, "1 ok");
	ok(!$cases[0]->todo, "not todo");
	ok($cases[0]->actual_ok, "actual ok");
	ok($cases[0]->normal, "normal");
	ok(!$cases[1]->ok, "2 nok -> nok");
	ok(!$cases[1]->todo, "not todo");
	ok($cases[1]->actual_nok, "actual nok");
	ok(!$cases[1]->normal, "not normal");
	ok($cases[2]->ok, "3 nok todo -> ok");
	ok($cases[2]->todo, "todo");
	ok(!$cases[2]->actual_ok, "actual nok");
	ok($cases[2]->normal, "normal");
	ok($cases[3]->ok, "4 ok todo -> ok");
	ok($cases[3]->todo, "todo");
	ok($cases[3]->actual_ok, "actual ok");
	ok($cases[3]->unexpected, "not normal");
}

{
	my $s = strap_this($m, skip_all => <<TAP);
1..0 # skipped: dancing beavers
TAP

	my @files = $s->test_files;
	is(@files, 1, "one file");

	isa_ok(my $f = $files[0], "Test::TAP::Model::File");

	ok($f->skipped, "whole file was skipped");
	is($f->cases, 0, "no test cases");

	is($f->ratio, 1, "ratio for file is 1");
	is($s->ratio, 1, "for suite too");
}

{
	my $s = strap_this($m, totals_1 => <<TAP1, totals_2 => <<TAP2);
1..2
ok 1 foo
not ok 2 bar
TAP1
1..4
ok 1 gorch
ok 2 baz # TODO fudge
not ok 3 poot # TODO zap
ok 4 bah # skip blah
TAP2

	is($s->test_files, 2, "two test files");
	ok($s->nok, "suite as a whole is not ok");

	my @files = $s->test_files;
	ok(!$files[0]->ok, "first file not ok");
	ok($files[1]->ok, "second file ok");

	is($files[0]->ratio, 1/2, "first file ratio");
	is($files[1]->ratio, 1/1, "second file ratio");

	is($s->total_ratio, 5/6, "total ratio");
	is($s->ratio, $s->total_ratio, "ratio alias also works");
	is($files[0]->percentage, "50.00%", "percentage of file");
	like($s->total_percentage, qr/^\d+(?:\.\d+)?%$/, "percentage is well formatted");

	my %expected = (
		seen	=> [ 2, 4],
		ok		=> [ 1, 4 ],
		nok		=> [ 1, 0 ],
		todo	=> [ 0, 2 ],
		skipped	=> [ 0, 1 ],
		unexpectedly_succeeded => [ 0, 1 ],
	);

	foreach my $method (keys %expected){
		my $fmeth = "${method}_tests";
		for my $i (0, 1){
			c_is(sub { $files[$i]->$fmeth }, $expected{$method}[$i], "file $i $method");
		}

		my $smeth = "total_$method";
		is($s->$smeth, sum(@{ $expected{$method} }), "total $method");
	}
}


{
	my $s = strap_this($m, no_plan => <<TAP);
ok 1
ok 2
ok 3
TAP
	
	ok(!$s->ok, "suite isn't ok yet");
	my $f = ($s->test_files)[0];
	is($f->planned, 0, "no tests planned");
	is($f->seen, 3, "but 3 tests seen");
}

{
	my $s = strap_this($m, plan_at_end => <<TAP);
ok 1
ok 2
ok 3
1..3
TAP
	
	ok($s->ok, "suite ok");
	my $f = ($s->test_files)[0];
	is($f->planned, 3, "plan at end registered");
	is($f->seen, 3, "but 3 tests seen");

	like(($f->test_cases)[0]->str, qr{1/0}, "str contains 1/0");
}

{
	my $s = strap_this($m, bad_plan => <<TAP);
1..2
ok 1
ok 2
ok 3
TAP
	ok(!$s->ok, "suite not ok");
	my $f = ($s->test_files)[0];
	is($f->planned, 2, "two planned");
	is($f->actual_cases, 3, "actually seen 3");
	is($f->cases, 3, "seen 3");
	ok(($f->cases)[0]->planned, "case 1 was planned");
	ok(($f->cases)[2]->unplanned, "case 3 was unplanned");
}

{
	my $s = strap_this($m, bail_no_tests => <<TAP);
1..10
Bail out!
TAP
	ok($s->nok, "suite not ok");
	my $f = ($s->test_files)[0];
	is($f->actual_cases, 0, "no cases in file");
	ok($f->bailed_out, "it bailed out");

	is($f->ratio, 0, "file ratio is 0");
	is($s->ratio, 0, "suite ratio is 0");
}

{
	my $s = strap_this($m, diag => <<TAP);
1..1
# before
# one
ok 1
# after
# two
TAP

	ok($s->ok, "suite is OK");
	my $f = ($s->test_files)[0];
	is($f->pre_diag, "# before\n# one\n", "diagnosis before tests");

	is($f->cases, 1, "one case");
	my $c = ($f->cases)[0];
	is($c->diag, "# after\n# two\n", "diagnosis belonging to case 1");
}


{
	my $s = strap_this($m, empty => <<TAP);
TAP

	ok($s->nok, "suite is not OK");
	is($s->ratio, 0, "ratio is 0");
	is($s->total_percentage, "0.00%", "zero percent");
	is($s->test_files, 1, "one file");
	my $f = ($s->test_files)[0];
	ok($f->nok, "file is not OK");
	is($f->cases, 0, "no cases");
	is($f->planned, 0, "no plan either");
	is($f->ratio, 0, "ratio is 0");
	is($f->percentage, "0.00%", "zero percent");
}
