#!/usr/bin/perl
###########################################################################

use Test;
use Text::Scan;

BEGIN { plan tests => 3 }

$ref = new Text::Scan;

$ref->charclass('.,:;');
$ref->charclass('Aa');


$ref->insert('period. What', 'period. What');

my @answer = 
	$ref->scan('The semicolon, colon, and comma are equivalent to the period; WhAt else?');

ok($answer[0], 'period; WhAt');
ok($answer[1], 'period. What');

$ref->insert('period; What', 1);
$ref->insert('period: What', 1);

ok($ref->terminals, 1);

exit 0;

