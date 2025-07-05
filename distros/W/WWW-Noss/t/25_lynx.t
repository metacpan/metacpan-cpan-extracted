#!/usr/bin/perl
use 5.016;
use strict;

use Test::More;

use File::Spec;

use WWW::Noss::Lynx qw(lynx_dump);

my $HTML = File::Spec->catfile(qw/t data lynx.html/);

qx/lynx -version 2>&1/;

if ($? == -1) {
	plan skip_all => 'lynx not installed';
}

my $format = lynx_dump($HTML, width => 72);

like(
	$format,
	qr/This\s+is\s+a\s+test\s+HTML\s+document/,
	'lynx_dump ok'
);

like(
	$format,
	qr/This\s+document\s+will\s+be\s+ran\s+through\s+lynx/,
	'lynx_dump ok'
);

done_testing;

# vim: expandtab shiftwidth=4
