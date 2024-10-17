use strict;
use warnings;

use Test::More import => [ qw( BAIL_OUT use_ok ) ], tests => 1;

BEGIN {
  use_ok 'Time::Out' or BAIL_OUT 'Cannot load Time::Out module!';
}
