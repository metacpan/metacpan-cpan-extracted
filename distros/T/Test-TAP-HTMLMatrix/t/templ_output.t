#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 30;

use Test::TAP::Model::Visual;

# TODO
# use some kind of XML test module (They were all veeerrry slow)

my $m;
BEGIN { use_ok($m = "Test::TAP::HTMLMatrix") }

my $s = Test::TAP::Model::Visual->new;

my $f = $s->start_file("foo");
eval { $f->{results} = $s->analyze("foo", [split /\n/, <<TAP]) };
1..6
ok 1 foo
not ok 2 bar
ok 3 gorch # skip foo
ok 4 # TODO bah
not ok 5 # TODO ding
Bail out!
TAP

isa_ok(my $t = $m->new($s, "extra"), $m);

for my $no_js (1, 0) {
	$t->no_javascript($no_js);
	my $detail_html = $t->detail_html;

	like($detail_html, qr{<html.*/html>}s, "detail view has <html> tags");

	like($detail_html, qr/ok 1 foo/, "contains subtest 1 line");
	like($detail_html, qr/not ok 2 bar/, "subtest 2 line");
	like($detail_html, qr/ok 3 gorch/, "subtest 3 line");

	like($detail_html, qr/66\.67%/, "contains percentage");

	like($detail_html, qr/BAILED OUT/, "something bailed out in there");

	like($detail_html, qr/4\s+ok/is, "ok summary");
	like($detail_html, qr/2\s+failed/is, "contains fail summary");
	like($detail_html, qr/1\s+skipped/is, "contains skip summary");
	like($detail_html, qr/2\s+todo/is, "contains skip summary");
	like($detail_html, qr/1\s+unexpectedly\s+succeeded/is, "contains skip summary");

	like($detail_html, qr/6/, "the number 6 is mentioned, that was our plan");

	my $summary_html = $t->summary_html;
	like($summary_html, qr{<html.*/html>}s, "summary has <html> tags");
	like($summary_html, qr/66\.67%/, "contains percentage");
}

