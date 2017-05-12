use strict;
use warnings;
use Test::More tests => 1;

my $module = "Time::StopWatchWithMessage";

eval "require $module"
    or BAIL_OUT( "Could not load module[$module].[$@]" );

new_ok( $module );

