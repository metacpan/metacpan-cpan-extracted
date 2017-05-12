#!/usr/bin/perl
###########################################################################

use Test;
use Text::Scan;

BEGIN { plan tests => 2 }

$ref = new Text::Scan;

$ref->ignore("\n\r<>()");


$ref->insert('bla', 'bla');

my @answer = $ref->scan("yada b\n<>la yada");

ok($answer[0], "b\n<>la");
ok($answer[1], 'bla');


exit 0;

