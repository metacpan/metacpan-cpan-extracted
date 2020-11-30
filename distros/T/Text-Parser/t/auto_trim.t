
use strict;
use warnings;

use Test::More;
use Test::Exception;

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

my $p2 = Text::Parser->new();
isa_ok( $p2, 'Text::Parser' );
throws_ok {
    $p2->custom_line_trimmer('');
}
'Moose::Exception::ValidationFailedForInlineTypeConstraint';
lives_ok {
    $p2->custom_line_trimmer( \&_trimmer );
}
'Sets the line trimmer';

lives_ok {
    $p2->read('t/trim_slash.txt');
    is_deeply(
        [ $p2->get_records() ],
        ["something 1 2 3 kskslu 28nks jk\n"],
        'Trimmed out slashes'
    );
}
'Everything works fine';
done_testing;

sub _trimmer {
    my $l = shift;
    $l =~ s/\s+\/\s+/ /g;
    return $l;
}
