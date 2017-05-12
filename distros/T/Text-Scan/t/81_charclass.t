#!/usr/bin/perl
###########################################################################

use Test;
use Text::Scan;

BEGIN { plan tests => 3 }

$ref = new Text::Scan;
$ref->usewild();

$ref->charclass('.,:;');
$ref->charclass('Aa');


$ref->insert('equivalent * * period. What', 'equivalent * * period. What');

my @answer = 
	$ref->scan('The semicolon, colon, and comma are equivalent to the period; WhAt else?');

ok($answer[0], 'equivalent to the period; WhAt'); # The actual text
ok($answer[1], 'equivalent * * period. What');    # The key matching the text

$ref->insert('period; What', 1);
$ref->insert('period: What', 1);

ok($ref->terminals, 2);

exit 0;

