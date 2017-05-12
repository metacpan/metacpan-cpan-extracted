#   $Id: 80-kwalitee.t 67 2008-06-29 14:17:37Z adam $

use strict;
use Test::More;

BEGIN {

    if ( not $ENV{TEST_AUTHOR} ) {
        plan( skip_all => 'Author test. Set $ENV{TEST_AUTHOR} to a true value to run.' );
    }

    eval { require Test::Kwalitee; };
    if ( $@ ) {
        plan skip_all => 'Test::Kwalitee not installed';
    }
    else {
        Test::Kwalitee->import();
    }
}
