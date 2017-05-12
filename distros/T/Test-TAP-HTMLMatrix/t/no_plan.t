#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 10;

use Test::TAP::Model::Visual;

# TODO
# use some kind of XML test module (They were all veeerrry slow)

my $m;
BEGIN { use_ok($m = "Test::TAP::HTMLMatrix") }

my $s = Test::TAP::Model::Visual->new;

my $f = $s->start_file("foo");
eval { $f->{results} = $s->analyze("foo", [split /\n/, <<TAP]) };
ok 1 foo
ok 2 bar
1..2
TAP

isa_ok(my $t = $m->new($s, "extra"), $m);

my $detail_html = $t->detail_html;

like($detail_html, qr{<html.*/html>}s, "detail view has <html> tags");

like($detail_html, qr/ok 1 foo/, "contains subtest 1 line");
like($detail_html, qr/ok 2 bar/, "subtest 2 line");

like($detail_html, qr/2\s+ok/is, "ok summary");
like($detail_html, qr/0\s+failed/is, "contains fail summary");
like($detail_html, qr/0\s+skipped/is, "contains skip summary");
like($detail_html, qr/0\s+todo/is, "contains skip summary");
like($detail_html, qr/0\s+unexpectedly\s+succeeded/is, "contains skip summary");

