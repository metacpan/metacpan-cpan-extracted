#!/usr/bin/perl

use strict;
use warnings;

use Cwd;

alarm 1000; # don't leave extra processes in case of test failures

return sub {
    my $env = shift;
    if ($env->{PATH_INFO} =~ /cwd/) {
        return [ 200, [], [ "cwd: ".cwd ] ];
    }
    if ($env->{PATH_INFO} =~ /env/) {
        return [ 200, [], [ "XXX: $ENV{XXX}" ] ];
    }
    else {
        return [ 200, [], ["ok"]];
    }
};
