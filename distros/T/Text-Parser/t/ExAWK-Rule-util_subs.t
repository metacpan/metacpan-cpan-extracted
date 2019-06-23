
use strict;
use warnings;

use Test::More;
use Test::Exception;
use Import::Into;

BEGIN {
    use_ok 'Text::Parser';
    String::Index->import::into( 'Text::Parser::Rule',
        qw(cindex ncindex crindex ncrindex) );
    use_ok 'Text::Parser::Rule';
}

lives_ok {
    my $parser = Text::Parser->new();
    $parser->BEGIN_rule( do => '' );
    $parser->BEGIN_rule( do => '', if => 1, continue_to_next => 1 );
    $parser->BEGIN_rule( do => '', dont_record => 1 );
    $parser->add_rule( if => 'm/washing/i' );
    $parser->read('t/names.txt');
    is_deeply(
        [ $parser->get_records ],
        ["ADDRESS: 301, Washington Ave, London, UK\n"],
        'Everything read in'
    );
    $parser->clear_rules;
    ok( not( $parser->_has_begin_rule ),
        'Does not have a begin rule anymore'
    );
    $parser->read('t/names.txt');
    is( scalar( $parser->get_records ), 9, 'Back to original' );
    $parser->add_rule(
        if => 'looks_like_number($2)',
        do =>
            'my $pos = cindex($_, "0123456789"); return {ucfirst(lc($1)) => $pos}'
    );
    $parser->read('t/names.txt');
    is_deeply( [ $parser->get_records ], [ { 'Extract:' => 9 } ] );
}
'does not die';

done_testing;
