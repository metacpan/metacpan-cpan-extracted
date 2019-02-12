
use strict;
use warnings;

use Test::More;

BEGIN { use_ok 'Text::Parser'; }

my $fname = 't/lines-whitespace.txt';

my $parser = Text::Parser->new(
    auto_chomp     => 1,
    auto_trim      => 'b',
    multiline_type => 'join_last'
);
$parser->read($fname);
is( $parser->last_record,
    'This file has a lot ofwhitespacewhich should be trimmedso that it looks neat.',
    'Completely trimmed'
);

$parser->auto_trim('l');
$parser->read($fname);
is( $parser->last_record,
    'This file has a lot of               whitespacewhich should be trimmed                     so that it looks neat.     ',
    'Only left trimmed'
);

$parser->auto_trim('r');
$parser->read($fname);
is( $parser->last_record,
    '   This file has a lot of   whitespace which should be trimmed       so that it looks neat.',
    'Right whitespace trimmed'
);

done_testing;
