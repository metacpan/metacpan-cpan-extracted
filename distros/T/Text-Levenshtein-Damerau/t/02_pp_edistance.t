use strict;
use warnings;

use Test::More tests => 23;
use Text::Levenshtein::Damerau::PP qw/pp_edistance/;

# We test pp_edistance before edistance because edistance might be using ::XS backend and fail

is( pp_edistance('four','four'),   0, 'test pp_edistance matching');
is( pp_edistance('four','for'),    1, 'test pp_edistance insertion');
is( pp_edistance('four','fourth'), 2, 'test pp_edistance deletion');
is( pp_edistance('four','fuor'),   1, 'test pp_edistance transposition');
is( pp_edistance('four','fxxr'),   2, 'test pp_edistance substitution');
is( pp_edistance('four','FOuR'),   3, 'test pp_edistance case');
is( pp_edistance('four',''), 	   4, 'test pp_edistance target empty');
is( pp_edistance('','four'), 	   4, 'test pp_edistance source empty');
is( pp_edistance('',''), 		   0, 'test pp_edistance source & target empty');
is( pp_edistance('11','1'), 	   1, 'test pp_edistance numbers');
is( pp_edistance('xxx','x',1),    -1, 'test pp_edistance > max distance setting');
is( pp_edistance('xxx','xx',1),    1, 'test pp_edistance <= max distance setting');

# some extra maxDistance tests
is( pp_edistance("xxx","xxxx",1),   1,  'test xs_edistance misc 1');
is( pp_edistance("xxx","xxxx",2),   1,  'test xs_edistance misc 2');
is( pp_edistance("xxx","xxxx",3),   1,  'test xs_edistance misc 3');
is( pp_edistance("xxxx","xxx",1),   1,  'test xs_edistance misc 4');
is( pp_edistance("xxxx","xxx",2),   1,  'test xs_edistance misc 5');
is( pp_edistance("xxxx","xxx",3),   1,  'test xs_edistance misc 6');


# Test some utf8
use utf8;
no warnings; # Work around for Perl 5.6 and setting output encoding
is( pp_edistance('ⓕⓞⓤⓡ','ⓕⓞⓤⓡ'), 	0, 'test pp_edistance matching (utf8)');
is( pp_edistance('ⓕⓞⓤⓡ','ⓕⓞⓡ'), 	1, 'test pp_edistance insertion (utf8)');
is( pp_edistance('ⓕⓞⓤⓡ','ⓕⓞⓤⓡⓣⓗ'), 2, 'test pp_edistance deletion (utf8)');
is( pp_edistance('ⓕⓞⓤⓡ','ⓕⓤⓞⓡ'), 	1, 'test pp_edistance transposition (utf8)');
is( pp_edistance('ⓕⓞⓤⓡ','ⓕⓧⓧⓡ'), 	2, 'test pp_edistance substitution (utf8)');

