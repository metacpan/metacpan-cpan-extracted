#!/usr/bin/perl
###########################################################################

use Test;
use Text::Scan;

BEGIN { plan tests => 4 }

$ref = new Text::Scan;
$ref->ignorecase();

$ref->insert('PeRiOd. WhAt', 'PeRiOd. WhAt');

my @answer = 
	$ref->scan('The semicolon, colon, and comma are equivalent to the period. What else?');

ok( $#answer, 1 );

ok($answer[0], 'period. What'); # The actual text found
ok($answer[1], 'PeRiOd. WhAt'); # The key matching the text

$ref->insert('PERIOD. WHAT', 1);
$ref->insert('period. what', 1);

ok($ref->terminals, 1); # Equivalent patterns are identical internally

exit 0;

