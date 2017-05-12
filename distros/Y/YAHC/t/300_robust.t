#!/usr/bin/env perl

use strict;
use warnings;

use YAHC;
use POSIX;
use FindBin;
use HTTP::Tiny;
use Test::More;
use Data::Dumper;
use JSON qw/decode_json/;
use Time::HiRes qw/time sleep nanosleep/;
use List::Util qw/shuffle/;

use lib "$FindBin::Bin/..";
use t::Utils;

unless ($ENV{TEST_ROBUST}) {
    plan skip_all => "Enable robust testing by setting env: TEST_ROBUST=1";
}

unless (YAHC::SSL) {
    plan skip_all => 'IO::Socket::SSL 1.94+ required for this test!'
}

unless (t::Utils::_check_toxyproxy_and_reset()) {
    plan skip_all => 'Toxyproxy is not responsive, use $ENV{TOXYPROXY} to specify its address';
}

my $len = 50;
my $nrequests = 16;
note("generating $nrequests requests structures");
my @requests = map {
    $len *= 2;
    {
        path => '/record',
        body => t::Utils::_generate_sequence(int($len / 2) + int(rand($len))),
        ssl_options => {
            SSL_cert_file   => t::Utils::SSL_CRT,
            SSL_key_file    => t::Utils::SSL_KEY,
            SSL_verify_mode => 0, # SSL_VERIFY_NONE
        },
    }
} (1..$nrequests);

# [ $latency_ms, jitter_ms ]
# final latency = $latency +- rand($jitter)
my @latencies = ([10, 5], [50, 20], [100, 50], [500, 250]);
push @latencies, ([1000, 500], [10000, 5000]) if $ENV{TEST_ROBUST_LONG};

foreach my $proto ('http', 'https') {
    my $ssl = $proto eq 'https' ? 1 : 0;
    my ($spid, $chost, $cport) = t::Utils::_start_plack_server_on_random_port({ ssl => $ssl });
    my $caddr = "${chost}:${cport}";

    foreach my $settings (@latencies) {
        my ($latency, $jitter) = @{ $settings };
        subtest "robustness of $proto in case of latency $latency ms" => sub {
            my $addr = t::Utils::new_toxic(
                "yahc_robust_${proto}_latency_${latency}_jitter_${jitter}",
                $caddr,
                {
                    type        => 'latency',
                    attributes  => {
                        latency => int($latency),
                        jitter  => int($jitter),
                    },
                },
            );

            _do_requests_and_verify($addr, $ssl, @requests);
        }
    }

    note("killing web server $spid");
    delete t::Utils::_pids->{$spid};
    kill 'KILL', $spid;
}

# rate in kilobytes per second
my @rates = (100000, 10000, 1000);
push @rates, 100 if $ENV{TEST_ROBUST_LONG};

foreach my $proto ('http', 'https') {
    my $ssl = $proto eq 'https' ? 1 : 0;
    my ($spid, $chost, $cport) = t::Utils::_start_plack_server_on_random_port({ ssl => $ssl });
    my $caddr = "${chost}:${cport}";

    foreach my $rate (@rates) {
        subtest "robustness of $proto in case of $rate kilobytes per second bandwidth" => sub {
            my $addr = t::Utils::new_toxic(
                "yahc_robust_${proto}_bandwidth_${rate}",
                $caddr,
                {
                    type        => 'bandwidth',
                    attributes  => { rate => int($rate) },
                },
            );

            _do_requests_and_verify($addr, $ssl, @requests);
        }
    }

    note("killing web server $spid");
    delete t::Utils::_pids->{$spid};
    kill 'KILL', $spid;
}

my @signal_requests = shuffle (@requests, @requests, @requests,
                               @requests, @requests, @requests,
                               @requests, @requests, @requests);
my $nsignal_requests = scalar @signal_requests;

foreach my $proto ('http', 'https') {
    my $ssl = $proto eq 'https' ? 1 : 0;
    my ($spid, $chost, $cport) = t::Utils::_start_plack_server_on_random_port({ ssl => $ssl });
    my $caddr = "${chost}:${cport}";

    subtest "robustness of $proto in case of storm of signals" => sub {
        pipe(my $rh, my $wh) or die "failed to pipe: $!";

        my $ht = t::Utils::_get_http_tiny();
        ok($ht->get("$proto://$caddr/reset")->{success}, "reset server counters")
          or return;

        my $pid = t::Utils::_fork(sub {
            my $sigcnt = 0;
            local $SIG{HUP}  = 'IGNORE';
            local $SIG{USR1} = sub { $sigcnt++ };
            local $SIG{USR2} = sub { $sigcnt++ };

            my ($yahc, $yahc_storage) = YAHC->new({ account_for_signals => 1 });

            syswrite($wh, '1', 1);
            close($wh); # signal parent process
            close($rh);

            note("$$ client process start sending requests to $proto://$caddr");
            foreach my $request (@signal_requests) {
                my $c = $yahc->request({
                    host         => $caddr,
                    scheme       => $proto,
                    query_string => "sigcnt=$sigcnt",
                    %{ $request }
                });

                $yahc->run;

                die "we didn't get 200\n" unless ($c->{response}{status} || 0) == 200;
                die "body didn't match\n" unless ($c->{response}{body} || '') eq $request->{body};
            }

            note("$$ client process is done");
        });

        note("waiting for client to be ready");
        sysread($rh, my $b = '', 1);
        close($wh);
        close($rh);

        my $exit_code = 1024;
        my @signals = ('HUP', 'USR1', 'USR2', 'USR1', 'USR2' );
        note("start spaming client with signals " . join(',', @signals));

        my $t0 = time;
        while ($t0 + 10 >= time) {
            for (my $t1 = time; $t1 + 0.1 >= time;) {
                my $sig = $signals[int(rand(scalar @signals))];
                # note("send $sig to $pid");
                kill $sig, $pid;
                nanosleep 100000; # 100 microseconds
            }

            if (waitpid($pid, WNOHANG) != 0) {
                $exit_code = ($? >> 8);
                last;
            }
        }

        cmp_ok($exit_code, '==', 0, "client process exited with success")
            or return;

        note("analizing report");
        my $resp = $ht->get("$proto://$caddr/report");
        my @report = @{ decode_json($resp->{content} || '{}') };
        cmp_ok(scalar @report, '==', $nsignal_requests , "got $nsignal_requests reports");

        my $total_sigcnt = 0;
        my @report_body_lengths;
        my @body_length = map { length $_->{body} } @signal_requests;

        my $i = 1;
        foreach my $r (@report) {
            my $len = $r->{body_length} || 0;
            push @report_body_lengths, $len;
            my (undef, $sigcnt) = split(/=/, $r->{query_string} || '');
            $sigcnt ||= 0;
            note("client received $sigcnt signals during #$i request of $len bytes");
            $total_sigcnt += $sigcnt;
            $i++;
        }

        cmp_ok($total_sigcnt, '>', 0, "client process received signals");
        is_deeply(\@report_body_lengths, \@body_length, "bodies' length match");
    };

    note("killing web server $spid");
    delete t::Utils::_pids->{$spid};
    kill 'KILL', $spid;
}

sub _do_requests_and_verify {
    my ($addr, $ssl, @requests) = @_;
    my ($yahc, $yahc_storage) = YAHC->new;
    foreach my $request (@requests) {
        note(sprintf("request with body of %s bytes", length($request->{body})));

        my $c = $yahc->request({
            host   => $addr,
            scheme => $ssl ? 'https' : 'http',
            %{ $request }
        });
        $yahc->run;

        cmp_ok($c->{response}{status}, '==', 200, "We got 200 OK response");
        ok($c->{response}{body} eq $request->{body}, "Bodies match");
    }
}

END {
    kill 'KILL', $_ foreach keys %{ t::Utils::_pids() };
}

done_testing;
