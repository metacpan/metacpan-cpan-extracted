#!perl
use strict;
use utf8;
use warnings qw(all);

use AnyEvent::Util;
use Test::HTTP::AnyEvent::Server;
use Test::More;

plan skip_all => q(these tests are for automated testing)
    unless exists $ENV{AUTOMATED_TESTING};

SKIP: {
    ## no critic (ProhibitBacktickOperators)
    my $ab = qx(which ab);
    chomp $ab;
    skip q(requires Apache HTTP server benchmarking tool (usually /usr/bin/ab)), 4
        unless -x $ab;

    $AnyEvent::Log::FILTER->level(q(fatal));

    my $server = Test::HTTP::AnyEvent::Server->new;

    my $buf;
    my $num = 1000;

    $buf = '';
    my $cv = run_cmd
        [$ab => qw[
            -c 10
            -n], $num, qw[
            -r
        ], $server->uri . q(echo/head)],
        q(<)    => q(/dev/null),
        q(>)    => \$buf,
        q(2>)   => q(/dev/null),
        close_all => 1;
    $cv->recv;
    like($buf, qr{\bComplete\s+requests:\s*${num}\b}isx, q(benchmark complete));
    unlike($buf, qr{\bFailed\s+requests:\s*[1-9][0-9]*\b}isx, q(benchmark failed));
    unlike($buf, qr{\bWrite\s+errors:\s*[1-9][0-9]*\b}isx, q(benchmark write errrors));

    $buf = '';
    $cv = run_cmd
        [$ab => qw[
            -c 100
            -n], $num, qw[
            -i
            -r
        ], $server->uri . q(echo/head)],
        q(<)    => q(/dev/null),
        q(>)    => \$buf,
        q(2>)   => q(/dev/null),
        close_all => 1;
    $cv->recv;
    unlike($buf, qr{\bFailed\s+requests:\s*0\b}isx, q(benchmark failed));
}

done_testing(4);
