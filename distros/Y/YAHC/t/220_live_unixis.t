#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;
use YAHC qw/yahc_conn_last_error yahc_conn_state/;

unless ($ENV{TEST_LIVE}) {
    plan skip_all => "Enable live testing by setting env: TEST_LIVE=1";
}

if($ENV{http_proxy}) {
    plan skip_all => "http_proxy is set. We cannot test when proxy is required to visit google.com";
}

my ($yahc, $yahc_storage) = YAHC->new();

subtest "sequential requests" => sub {
    for my $i (1..100) {
        lives_ok {
            my $c = $yahc->request({
                host            => 'u.nix.is',
                port            => 80,
                request_timeout => 3,
                path            => "/?YAHC_test_nr=$i",
                head   => [
                    "X-Request-Nr" => $i,
                    "Referer" => "YAHC (file:" . __FILE__ . "; iteration: $i)",
                ],
            });

            $yahc->run;

            ok !yahc_conn_last_error($c), 'yahc_conn_last_error($conn) return undef, because we do not expect connect timeout to happen';
            cmp_ok($c->{response}{status}, '==', 200, "We got a 200 OK response");
            cmp_ok(yahc_conn_state($c), '==', YAHC::State::COMPLETED(), "We got COMPLETED state");
        } "We could make request number $i";
    }
};

subtest "parallel requests" => sub {
    for my $attempt (1..10) {
        lives_ok {
            my @cs;
            for my $i (1..10) {
                push @cs, $yahc->request({
                    host            => 'u.nix.is',
                    port            => 80,
                    request_timeout => 3,
                    path            => "/?YAHC_test_nr=$i",
                    head   => [
                        "X-Request-Nr" => $i,
                        "Referer" => "YAHC (file:" . __FILE__ . "; iteration: $i)",
                    ],
                });
            }

            $yahc->run;

            foreach my $c (@cs) {
                ok !yahc_conn_last_error($c), 'yahc_conn_last_error($conn) return undef, because we do not expect connect timeout to happen';
                cmp_ok($c->{response}{status}, '==', 200, "We got a 200 OK response");
                cmp_ok(yahc_conn_state($c), '==', YAHC::State::COMPLETED(), "We got COMPLETED state");
            }
        } "We could make attempt #$attempt";
    }
};

done_testing();
