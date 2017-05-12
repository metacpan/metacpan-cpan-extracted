#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 8;

use Test::TAP::Model::Visual;

my $m; BEGIN { use_ok($m = "Test::TAP::HTMLMatrix") };

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

isa_ok(my $t = $m->new($s, "blah"), $m);

my $inline_css_re = qr/border-collapse.*font-weight.*a:hover/s;

{
	$t->has_inline_css(1);
	my $html = $t->detail_html;
	like($html, qr/<style/, "HTML contains style tag");
	like($html, $inline_css_re,  "document contains typical CSS string");
	unlike($html, qr/htmlmatrix\.css/, "it doesn't mention the CSS file");
}

{
	$t->has_inline_css(0);
	my $html = $t->detail_html;
	like($html, qr/<link.*?rel="stylesheet"/, "non inline css version contains link with rel=stylesheet");
	unlike($html, $inline_css_re, "... but no inline css");
	like($html, qr/htmlmatrix\.css/, "it mentions the CSS file");
}

