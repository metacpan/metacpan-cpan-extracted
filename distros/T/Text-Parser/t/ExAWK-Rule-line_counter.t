use strict;
use warnings;

use Test::More;
use Test::Exception;
use Test::Output;

BEGIN {
    use_ok 'Text::Parser';
}

lives_ok {
    my $parser = Text::Parser->new();
    $parser->BEGIN_rule( do => '~count = 0;' );
    $parser->add_rule( do => '~count++;' );
    $parser->END_rule( do => 'print ~count,  "\n";' );
    stdout_is {
        $parser->read('t/names.txt');
    }
    "9\n", 'Prints number of lines to STDOUT';
    is( $parser->lines_parsed,
        scalar( $parser->get_records ),
        'Lines parsed is 9'
    );
    is_deeply( [ $parser->get_records ], [ 0 .. 8 ], 'All the records' );
}
'No compilation errors';

done_testing;
