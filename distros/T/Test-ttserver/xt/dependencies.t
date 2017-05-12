use strict;
use warnings;
use Test::Dependencies
    exclude => [qw/Test::Dependencies Test::ttserver/],
    style   => 'light';

ok_dependencies();
