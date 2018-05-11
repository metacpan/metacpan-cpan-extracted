
use strict;
use warnings;
use Test::More tests => 4;

use Types::Bool qw(true false is_bool to_bool);

is( \&true,    \&Types::Bool::true );
is( \&false,   \&Types::Bool::false );
is( \&is_bool, \&Types::Bool::is_bool );
is( \&to_bool, \&Types::Bool::to_bool );
