use strict;
use warnings;
use Test::More tests => 24;
use Text::Levenshtein::Damerau::XS qw/xs_edistance/;

is( xs_edistance('four','for'), 	1, 'test xs_edistance insertion');
is( xs_edistance('four','four'), 	0, 'test xs_edistance matching');
is( xs_edistance('four','fourth'), 	2, 'test xs_edistance deletion');
is( xs_edistance('four','fuor'), 	1, 'test xs_edistance transposition');
is( xs_edistance('four','fxxr'), 	2, 'test xs_edistance substitution');
is( xs_edistance('four','FOuR'), 	3, 'test xs_edistance case');
is( xs_edistance('four',''), 		4, 'test xs_edistance target empty');
is( xs_edistance('','four'), 		4, 'test xs_edistance source empty');
is( xs_edistance('',''), 			0, 'test xs_edistance source and target empty');
is( xs_edistance('111','11'), 		1, 'test xs_edistance numbers');
is( xs_edistance('xxx','x',1),     -1, 'test xs_edistance > max distance setting');
is( xs_edistance('xxx','xx',1),    	1, 'test xs_edistance <= max distance setting');

# some extra maxDistance tests
is( xs_edistance("xxx","xxxx",1),   1,  'test xs_edistance misc 1');
is( xs_edistance("xxx","xxxx",2),   1,  'test xs_edistance misc 2');
is( xs_edistance("xxx","xxxx",3),   1,  'test xs_edistance misc 3');
is( xs_edistance("xxxx","xxx",1),   1,  'test xs_edistance misc 4');
is( xs_edistance("xxxx","xxx",2),   1,  'test xs_edistance misc 5');
is( xs_edistance("xxxx","xxx",3),   1,  'test xs_edistance misc 6');


# Test some utf8
{
use utf8;
binmode STDOUT, ":encoding(utf8)";
is( xs_edistance('ⓕⓞⓤⓡ','ⓕⓞⓤⓡ'), 	0, 'test xs_edistance matching (utf8)');
is( xs_edistance('ⓕⓞⓤⓡ','ⓕⓞⓡ'), 	1, 'test xs_edistance insertion (utf8)');
is( xs_edistance('ⓕⓞⓤⓡ','ⓕⓞⓤⓡⓣⓗ') , 2, 'test xs_edistance deletion (utf8)');
is( xs_edistance('ⓕⓞⓤⓡ','ⓕⓤⓞⓡ'), 	1, 'test xs_edistance transposition (utf8)');
is( xs_edistance('ⓕⓞⓤⓡ','ⓕⓧⓧⓡ'), 	2, 'test xs_edistance substitution (utf8)');
is( xs_edistance('ⓕⓞⓤⓡ','ⓕⓧⓧⓡ',10), 2, 'test xs_edistance substitution with maxDistance=10 (utf8)');
}
