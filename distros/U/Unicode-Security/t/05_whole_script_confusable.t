use strict;
use warnings;
use Test::More;
use Unicode::Security qw(whole_script_confusable);

is whole_script_confusable(Latin => "DFRVz"), '', 'unconfusable ascii';
is whole_script_confusable(Cyrillic => "scope"), 1, 'scope; latin';
is whole_script_confusable(
    Latin => "\x{0455}\x{0441}\x{043e}\x{0440}\x{0435}"
), 1, 'scope; cyrillic';

done_testing;
