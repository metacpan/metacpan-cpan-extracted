#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 6;

my $m;
BEGIN { use_ok($m = "Test::TAP::Model::Colorful") }

my $ratio;
{
	package Foo;
	use base $m;

	sub ratio { $ratio }
}

	
can_ok($m, "color");

$ratio = 0.5;

like(Foo->color, qr/^#.{6}$/, "format is sane");

$ratio = 1;

like(Foo->color, qr/^#00ff00$/i, "ratio 1 -> green");

can_ok($m, "color_css");

like(Foo->color_css, qr/^\s*background-color:\s+#.{6}\s*$/, "css looks valid");
