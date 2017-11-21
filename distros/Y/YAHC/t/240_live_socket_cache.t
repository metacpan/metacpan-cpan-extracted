#!/usr/bin/env perl

use strict;
use warnings;

use YAHC qw/
    yahc_conn_state
    yahc_retry_conn
    yahc_reinit_conn
    yahc_conn_errors
    yahc_conn_attempt
    yahc_conn_last_error
    yahc_conn_attempts_left
/;

use FindBin;
use Test::More;
use Data::Dumper;
use Time::HiRes qw/time sleep/;

use lib "$FindBin::Bin/..";
use t::Utils;

unless ($ENV{TEST_LIVE}) {
    plan skip_all => "Enable live testing by setting env: TEST_LIVE=1";
}

my (undef, $host, $port) = t::Utils::_start_plack_server_on_random_port({
    keep_alive => 1,
    server => 'Starman', # for HTTP/1.1
});

subtest "no cache" => sub {
    my %socket_cache;
    my ($yahc, $yahc_storage) = YAHC->new();

    my $c1 = $yahc->request({
        host => $host,
        port => $port,
    });

    $yahc->run;

    ok !yahc_conn_last_error($c1), 'We expect no errors';
    cmp_ok($c1->{response}{status}, '==', 200, "We got 200 OK response");
    cmp_ok(keys %socket_cache, '==', 0, "No caching unless set");
};

subtest "request with socket cache" => sub {
    my %socket_cache;
    my ($yahc, $yahc_storage) = YAHC->new({
        socket_cache => \%socket_cache
    });

    my $c1 = $yahc->request({
        host => $host,
        port => $port,
    });

    $yahc->run;

    ok !yahc_conn_last_error($c1), 'We expect no errors';
    cmp_ok($c1->{response}{status}, '==', 200, "We got 200 OK response");
    cmp_ok(keys %socket_cache, '==', 1, "We got one entry in socket cache");
};

subtest "reuse connection from socket cache" => sub {
    my %socket_cache;
    my ($yahc, $yahc_storage) = YAHC->new({
        socket_cache => \%socket_cache
    });

    my $num_of_connections = 0;
    my $c1 = $yahc->request({
        host => $host,
        port => $port,
        connected_callback => sub { $num_of_connections++ },
    });

    $yahc->run;

    ok !yahc_conn_last_error($c1), 'We expect no errors';
    cmp_ok($c1->{response}{status}, '==', 200, "We got 200 OK response");
    cmp_ok(keys %socket_cache, '==', 1, "We got one entry in socket cache");

    my $c2 = $yahc->request({
        host => $host,
        port => $port,
        connected_callback => sub { $num_of_connections++ },
    });

    $yahc->run;

    ok !yahc_conn_last_error($c2), 'We expect no errors';
    cmp_ok($c2->{response}{status}, '==', 200, "We got 200 OK response");
    cmp_ok(keys %socket_cache, '==', 1, "We got one entry in socket cache");
    cmp_ok $num_of_connections, '==', 1, "Also connection_callback should be called only once";
};

END { kill 'INT', $_ foreach keys %{ t::Utils::_pids() } }

done_testing;
