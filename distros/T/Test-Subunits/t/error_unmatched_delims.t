use 5.010;
use strict;
use warnings;
use lib 'tlib';

use Test::More;
plan tests => 4;


# Test for syntax errors (unmatched ##{ and ##})...

ok !eval q{ use Test::Subunits 'UnclosedOpeningDelim'; 1; }
    => 'Detected unmatched closing ##{';

like $@, qr/\AUnmatched ##\{/ => 'Correct error message';

ok !eval q{ use Test::Subunits 'UnopenedClosingDelim'; 1; }
    => 'Detected unmatched closing ##}';

like $@, qr/\AUnmatched ##\}/ => 'Correct error message';

done_testing();

