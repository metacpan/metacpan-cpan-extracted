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

my (undef, $host, $port) = t::Utils::_start_plack_server_on_random_port();
my (undef, $ch_host, $ch_port) = t::Utils::_start_plack_server_on_random_port({ chunked => 1 });

my ($yahc, $yahc_storage) = YAHC->new;

for my $len (0, 1, 2, 8, 23, 345, 1024, 65535, 131072, 9812, 19874, 1473451, 10000000) {
    my $body = t::Utils::_generate_sequence($len);
    subtest "content_length_$len" => sub {
        my $c = $yahc->request({
            host => $host,
            port => $port,
            path => '/record',
            body => $body,
            head => [ 'Content-Type' => 'raw' ]
        });

        $yahc->run;

        cmp_ok($c->{response}{body}, 'eq', $body, "We got expected body");
        cmp_ok($c->{response}{head}{'Content-Length'}, '==', $len, "We got expected Content-Length");
        cmp_ok($c->{response}{head}{'Content-Type'}, 'eq', 'raw', "We got expected Content-Type");
    };

    subtest "chunked_content_length_$len" => sub {
        my $c = $yahc->request({
            host => $ch_host,
            port => $ch_port,
            path => '/record',
            body => $body,
            head => [ 'Content-Type' => 'raw' ]
        });

        $yahc->run;

        cmp_ok($c->{response}{body}, 'eq', $body, "We got expected body");
        cmp_ok($c->{response}{head}{'Content-Type'}, 'eq', 'raw', "We got expected Content-Type");
    };
}

subtest "callbacks" => sub {
    my $init_callback;
    my $connecting_callback;
    my $connected_callback;
    my $writing_callback;
    my $reading_callback;
    my $callback;

    my $c = $yahc->request({
        host => $host,
        port => $port,
        retries => 5,
        request_timeout => 1,
        init_callback        => sub { $init_callback = 1 },
        connecting_callback => sub { $connecting_callback = 1 },
        connected_callback   => sub { $connected_callback = 1 },
        writing_callback     => sub { $writing_callback = 1 },
        reading_callback     => sub { $reading_callback = 1 },
        callback             => sub { $callback = 1 },
    });

    $yahc->run;

    ok !yahc_conn_last_error($c), "no errors";
    if (yahc_conn_last_error($c)) {
        diag Dumper(yahc_conn_errors($c));
    }

    ok $init_callback,          "init_callback is called";
    ok $connecting_callback,    "connecting_callback is called";
    ok $connected_callback,     "connected_callback is called";
    ok $writing_callback,       "writing_callback is called";
    ok $reading_callback,       "reading_callback is called";
    ok $callback,               "callback is called";
};

subtest "connect_timeout" => sub {
    my $c = $yahc->request({
        host => $host,
        port => $port,
        connect_timeout => 0.1,
        connecting_callback => sub { sleep 0.2 },
    });

    $yahc->run;

    my $has_timeout = grep { $_->[0] & YAHC::Error::CONNECT_TIMEOUT() } @{ yahc_conn_errors($c) || []};
    is($has_timeout, 1, "We got YAHC::Error::CONNECT_TIMEOUT()");
    cmp_ok($c->{response}{status}, '!=', 200, "We didn't get a 200 OK response");
};

subtest "drain_timeout" => sub {
    my $c = $yahc->request({
        host => $host,
        port => $port,
        drain_timeout => 0.1,
        writing_callback => sub { sleep 0.2 },
    });

    $yahc->run;

    my $has_timeout = grep { $_->[0] & YAHC::Error::DRAIN_TIMEOUT() } @{ yahc_conn_errors($c) || []};
    is($has_timeout, 1, "We got YAHC::Error::DRAIN_TIMEOUT()");
    cmp_ok($c->{response}{status}, '!=', 200, "We didn't get a 200 OK response");
};

subtest "request_timeout" => sub {
    my $c = $yahc->request({
        host => $host,
        port => $port,
        request_timeout => 0.1,
        reading_callback => sub { sleep 0.2 },
    });

    $yahc->run;

    my $has_timeout = grep { $_->[0] & YAHC::Error::REQUEST_TIMEOUT() } @{ yahc_conn_errors($c) || [] };
    is($has_timeout, 1, "We got YAHC::Error::REQUEST_TIMEOUT()");
    cmp_ok($c->{response}{status}, '!=', 200, "We didn't get a 200 OK response");
};

subtest "lifetime_timeout" => sub {
    my $c = $yahc->request({
        host => $host,
        port => $port,
        lifetime_timeout => 0.1,
        writing_callback => sub { sleep 0.2 },
    });

    $yahc->run;

    my $has_timeout = grep { $_->[0] & YAHC::Error::LIFETIME_TIMEOUT() } @{ yahc_conn_errors($c) || [] };
    is($has_timeout, 1, "We got YAHC::Error::LIFETIME_TIMEOUT()");
    cmp_ok($c->{response}{status}, '!=', 200, "We didn't get a 200 OK response");
};

subtest "retry due to DNS error and connection error" => sub {
    my $rnd_port = t::Utils::_generaete_random_port();
    my $c = $yahc->request({
        host => [
            $host . "_non_existent:$port",
            $host . "_non_existent:$port",
            "127.0.0.1:$rnd_port",
            "127.0.0.1:$rnd_port",
            "$host:$port"
        ],
        retries => 4,
    });

    $yahc->run;

    cmp_ok($c->{response}{status}, '==', 200, "We got a 200 OK response");
    cmp_ok(yahc_conn_state($c), '==', YAHC::State::COMPLETED(), "We got COMPLETED state");
    cmp_ok(yahc_conn_attempt($c), '==', 5, "We did 5 attempts");
};

subtest "retry two connections due to DNS error" => sub {
    my $c1 = $yahc->request({
        host => [ $host . "_non_existent", $host . "_non_existent", $host ],
        port => $port,
        retries => 2,
    });

    my $c2 = $yahc->request({
        host => [ $host . "_non_existent", $host ],
        port => $port,
        retries => 1,
    });

    $yahc->run;

    cmp_ok($c1->{response}{status}, '==', 200, "first request got a 200 OK response");
    cmp_ok(yahc_conn_state($c1), '==', YAHC::State::COMPLETED(), "first request got COMPLETED state");
    cmp_ok(yahc_conn_attempt($c1), '==', 3, "first request did 3 attempts");

    cmp_ok($c2->{response}{status}, '==', 200, "second request got a 200 OK response");
    cmp_ok(yahc_conn_state($c2), '==', YAHC::State::COMPLETED(), "second request got COMPLETED state");
    cmp_ok(yahc_conn_attempt($c2), '==', 2, "second request did 2 attempts");
};

subtest "retry with backoff delay" => sub {
    my $c = $yahc->request({
        host => [ $host . "_non_existent", $host . "_non_existent_1", $host ],
        port => $port,
        retries => 2,
        backoff_delay => 2,
        request_timeout => 1,
    });

    my $start = time;
    $yahc->run;
    my $elapsed = time - $start;

    cmp_ok($c->{response}{status}, '==', 200, "We got a 200 OK response");
    cmp_ok(yahc_conn_state($c), '==', YAHC::State::COMPLETED(), "We got COMPLETED state");
    cmp_ok($elapsed, '>=', 4, "elapsed is greater than backoff_delay * retries")
};

subtest "manual retry with backoff delay" => sub {
    my $c = $yahc->request({
        host => [ $host, $host ],
        port => $port,
        retries => 1,
        request_timeout => 1,
        callback => sub {
            my ($conn, $err) = @_;
            yahc_retry_conn($conn, { backoff_delay => 2 })
                if yahc_conn_attempts_left($conn) > 0;
        }
    });

    my $start = time;
    $yahc->run;
    my $elapsed = time - $start;

    cmp_ok($c->{response}{status}, '==', 200, "We got a 200 OK response");
    cmp_ok(yahc_conn_state($c), '==', YAHC::State::COMPLETED(), "We got COMPLETED state");
    cmp_ok(yahc_conn_attempt($c), '==', 2, "request did two attempts");
    cmp_ok($elapsed, '>=', 2, "elapsed is greater than 2 seconds")
};

subtest "retry with backoff delay due to timeout" => sub {
    my $start = time;

    my $c = $yahc->request({
        host => [ $host, $host . '_non_existent', $host ],
        port => $port,
        retries => 2,
        backoff_delay => 4,
        connect_timeout => 0.5,
        connecting_callback => sub {
            sleep 1 if yahc_conn_attempt($_[0]) <= 1; # fail 1st and and 2nd attempts
        },
    });

    $yahc->run;
    my $elapsed = time - $start;

    cmp_ok($c->{response}{status}, '==', 200, "We got a 200 OK response");
    cmp_ok(yahc_conn_state($c), '==', YAHC::State::COMPLETED(), "We got COMPLETED state");
    cmp_ok($elapsed, '>=', 4, "elapsed is greater than backoff_delay");

    my @errors = @{ yahc_conn_errors($c) || [] };
    ok(@errors == 2, "We got two errors");

    if (@errors == 2) {
        ok($errors[0][0] & YAHC::Error::CONNECT_TIMEOUT(), "First error is CONNECT_TIMEOUT");
        ok($errors[1][0] & YAHC::Error::CONNECT_ERROR(), "Second error is CONNECT_ERROR");
    }
};

subtest "retry with backoff delay and lifetime timeout" => sub {
    my $c = $yahc->request({
        host => [ $host . "_non_existent", $host . "_non_existent_1", $host ],
        port => $port,
        retries => 2,
        backoff_delay => 1,
        request_timeout => 1,
        lifetime_timeout => 4,
    });

    my $start = time;
    $yahc->run;
    my $elapsed = time - $start;

    cmp_ok(int($elapsed), '<=', 4, "elapsed is smaller than lifetime");
    cmp_ok($c->{response}{status}, '==', 200, "We didn't get 200 OK response");
    cmp_ok(yahc_conn_state($c), '==', YAHC::State::COMPLETED(), "We got COMPLETED state");
};

subtest "retry with backoff delay and lifetime timeout triggering lifetime timeout" => sub {
    my $c = $yahc->request({
        host => [ $host . "_non_existent", $host . "_non_existent_1", $host ],
        port => $port,
        retries => 2,
        backoff_delay => 2,
        request_timeout => 1,
        lifetime_timeout => 4,
    });

    my $start = time;
    $yahc->run;
    my $elapsed = time - $start;

    my ($err) = yahc_conn_last_error($c);
    cmp_ok($err & YAHC::Error::LIFETIME_TIMEOUT(), '==', YAHC::Error::LIFETIME_TIMEOUT(), "We got lifetime timeout");
    cmp_ok(int($elapsed), '<=', 4, "elapsed is smaller than lifetime");
    cmp_ok($c->{response}{status}, '!=', 200, "We didn't get 200 OK response");
    cmp_ok(yahc_conn_state($c), '==', YAHC::State::COMPLETED(), "We got COMPLETED state");
};

subtest "reinitiaize connection" => sub {
    my $first_attempt = 1;
    my $c = $yahc->request({
        host => $host . "_non_existent",
        port => $port,
        request_timeout => 1,
        callback => sub {
            my ($conn, $err) = @_;
            yahc_reinit_conn($conn, { host => $host }) if $err && $first_attempt;
            $first_attempt = 0;
        },
    });

    $yahc->run;

    ok !$first_attempt;
    cmp_ok($c->{response}{status}, '==', 200, "We got a 200 OK response");
    cmp_ok(yahc_conn_state($c), '==', YAHC::State::COMPLETED(), "We got COMPLETED state");
};

END { kill 'KILL', $_ foreach keys %{ t::Utils::_pids() } }

done_testing;
