use strict;
use warnings;
use Test::More tests => 1;

my $module = "Time::StopWatchWithMessage";

my @methods = qw(
    new
    start  stop
    collapse  _output  output  print  warn
);

eval "require $module"
    or BAIL_OUT( "Could not load module[$module].[$@]" );

can_ok( $module, @methods );

