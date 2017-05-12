#!/usr/bin/env perl

use strict;
use warnings;

use YAHC qw/yahc_conn_errors/;
use Net::Ping;
use Test::More;
use Data::Dumper;
use Time::HiRes qw/time/;

unless ($ENV{TEST_LIVE}) {
    plan skip_all => "Enable live testing by setting env: TEST_LIVE=1";
}

my @errors;
my @elapsed;
my $generated = 0;
my $timeout = 0.5;

for my $attempt (1..10) {
    # find a ip and confirm it is not reachable.
    my $pinger = Net::Ping->new("tcp", 2);
    $pinger->port_number(80);

    my $ip;
    my $iter = 10;
    do {
        $ip = join ".", 172, (int(rand()*15+16)), int(rand()*250+1),  int(rand()*255+1);
    } while($iter-- > 0 && $pinger->ping($ip));

    next if $iter == 0;
    $generated = 1;
    pass "attempt $attempt ip generated = $ip";

    local $SIG{ALRM} = sub { BAIL_OUT('ALARM') };
    alarm(10); # 10 sec of timeout

    my ($yahc, $yahc_storage) = YAHC->new({
        account_for_signals => 1
    });

    my $start = time;
    my $conn = $yahc->request({
        host            => $ip,
        connect_timeout => $timeout,
    });

    $yahc->run(YAHC::State::CONNECTED);

    my $elps = time - $start;
    push @elapsed, $elps;
    pass("attempt $attempt elapsed " . sprintf("%.3fs", $elps));

    push @errors, grep {
       $_->[0] & YAHC::Error::CONNECT_TIMEOUT()
    } @{ yahc_conn_errors($conn) || [] };
    last if @errors;
}

plan skip_all => "Cannot randomly generate an unreachable IP." unless $generated;
ok($_ <= $timeout * 2, "elapsed is roughly same as timeout") for @elapsed;
ok(@errors > 0, <<TEXT
Got CONNECT_TIMEOUT errors. If you see this error it's not necessary a bug!
Most likely the test failed to find unavailable IP address.
TEXT
);

done_testing;
