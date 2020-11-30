
use strict;
use warnings;

use Test::More;
use Test::Exception;
use Text::Parser::Error;

throws_ok {
    parser_exception();
}
'Text::Parser::Error', 'Produces an unknown error message';

done_testing;

