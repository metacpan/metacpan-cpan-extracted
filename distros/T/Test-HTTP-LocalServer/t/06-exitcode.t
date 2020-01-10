#!perl -w
use strict;
use warnings;
use Test::HTTP::LocalServer;

use Test::More tests => 3;

{
my $server = Test::HTTP::LocalServer->spawn;
}
is $?, 0, "We have a zero exit code";

$? = 1;
is $?, 1, "We set up the exit code correctly";
{
    note $?;
    my $server = Test::HTTP::LocalServer->spawn;
    note $?;
}
note $?;
is $?, 1, "We leave the exit code untouched in the destructor";

