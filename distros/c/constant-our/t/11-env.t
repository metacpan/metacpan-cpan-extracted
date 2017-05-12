#!perl -T

use strict;
use warnings;

use Test::More tests => 2;

BEGIN
{
    $ENV{CONSTANT_OUR_DEBUG} = 1;
    $ENV{CONSTANT_OUR_TEST1} = 'test1';
}

package My::Test;
use Test::More;
use constant::our qw(DEBUG TEST1);

is( DEBUG,     1 );
is( TEST1, 'test1' );
