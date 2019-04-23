
use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN {
    use_ok 'Text::Parser::Errors';
}

dies_ok {
    invalid_filename( name => [ 2, 3, 4 ] );
}
'Invalid error attribute';

dies_ok {
    invalid_filename( name => undef );
}
'Invalid error attribute';

dies_ok {
    unexpected_eof( discontd => 'something', line_num => 'something else' );
}
'Invalid error attribute';

dies_ok {
    unexpected_eof( discontd => 'something', line_num => undef );
}
'Invalid error attribute';

done_testing;
