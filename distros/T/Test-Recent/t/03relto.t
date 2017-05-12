#!/usr/bin/env perl

use strict;

use Test::More tests => 3;
use Test::Recent qw(recent);
use Test::Builder::Tester;

# manually create a now
my $now = DateTime->new(
        year => '2012',
        month => '05',
        day => '23',
        hour => '10',
        minute => '36',
        second => '30',
        time_zone => 'Z',
);

# manually set the clock
{
    local $Test::Recent::RelativeTo = $now;
    recent $now, "DateTime";
}

{
    local $Test::Recent::RelativeTo = 1337769390;
    recent $now, "epoch";
}

{
    local $Test::Recent::RelativeTo = '2012-05-23T10:36:30Z';
    recent $now, "string";
}



