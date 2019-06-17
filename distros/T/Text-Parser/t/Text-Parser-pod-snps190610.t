
use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN {
    use_ok 'Text::Parser';
}

lives_ok {
    my $parser = Text::Parser->new();
    $parser->add_rule( do => '' );
    $parser->read('t/names.txt');
    is( scalar( $parser->get_records ), 0, 'Got nothing' );
}
'does not die';

lives_ok {
    my $parser = Text::Parser->new();
    $parser->add_rule( if => 'm/NAME/' );
    $parser->read('t/names.txt');
    is( scalar( $parser->get_records ), 5, 'Got 5 things' );
}
'does not die';

lives_ok {
    my $parser = Text::Parser->new( auto_split => 1 );
    $parser->add_rule( if => '$1 eq "NAME:"', do => 'lc($2)' );
    $parser->read('t/names.txt');
    is( scalar( $parser->get_records ), 3, 'Got only 3 things' );
    is_deeply(
        [ $parser->get_records ],
        [qw(balaji elizabeth brian)],
        'everything lower case and file'
    );
}
'does not die';

lives_ok {
    my $parser = Text::Parser->new();
    $parser->add_rule(
        if               => '$1 eq "NAME:"',
        do               => 'lc($2)',
        dont_record      => 1,
        continue_to_next => 1
    );
    $parser->read('t/names.txt');
    is( scalar( $parser->get_records ), 0, 'Got nothing things' );
    is_deeply( [ $parser->get_records ], [], 'empty array' );
}
'does not die';

done_testing;
