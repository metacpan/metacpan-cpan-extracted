#!/usr/bin/perl -w
use 5.010;
use strict;
use warnings;
use autodie;
use Test::More;

use WebService::HabitRPG;

# Tests to see if keep-alives are being set correctly.

{
    my $hrpg = WebService::HabitRPG->new(
        api_token => 'test',
        user_id   => 'test',
    );

    isa_ok($hrpg->agent->conn_cache, 'LWP::ConnCache');
}

{
    my $hrpg = WebService::HabitRPG->new(
        api_token  => 'test',
        user_id    => 'test',
        keep_alive => 0,
    );

    is($hrpg->agent->conn_cache, undef, "keep-alives disabled");
}

{
    my $hrpg = WebService::HabitRPG->new(
        api_token  => 'test',
        user_id    => 'test',
        keep_alive => 3,
    );

    is($hrpg->agent->conn_cache->total_capacity, 3, "Keep-alives can be set");
}

done_testing;
