#!/usr/bin/perl

use strict;
use warnings;

BEGIN { delete $ENV{http_proxy} }

# workaround for HTTP::Tiny + Test::TCP
BEGIN { $INC{'threads.pm'} = 0 }
sub threads::tid { }
use HTTP::Tiny;
use Test::TCP;
BEGIN { delete $INC{'threads.pm'} }
BEGIN { $SIG{__WARN__} = sub { warn @_ if not $_[0] =~ /^Subroutine tid redefined/ } }

use HTTP::Request::Common;
use Plack::Test;
use Test::More;

if ($^O eq 'MSWin32' and $] >= 5.016 and $] < 5.019005 and not $ENV{PERL_TEST_BROKEN}) {
    plan skip_all => 'Perl with bug RT#40565 on MSWin32';
    exit 0;
}

$Plack::Test::Impl = 'Server';
$ENV{PLACK_SERVER} = 'Thrall';
$ENV{PLACK_QUIET} = 1;

test_psgi
    app => sub {
        my $env = shift;
        return [ 200, [ 'Content-Type' => 'text/plain' ], [threads->tid] ];
    },
    client => sub {
        my %seen_pid;
        my $cb = shift;
        sleep 1;
        for (1..23) {
            my $res = $cb->(GET "/");
            $seen_pid{$res->content}++;
        }
        cmp_ok(keys(%seen_pid), '<=', 10, 'In non-harakiri mode, pid is reused');
        sleep 1;
    };

test_psgi
    app => sub {
        my $env = shift;
        $env->{'psgix.harakiri.commit'} = $env->{'psgix.harakiri'};
        return [ 200, [ 'Content-Type' => 'text/plain' ], [threads->tid] ];
    },
    client => sub {
        my %seen_pid;
        my $cb = shift;
        sleep 1;
        for (1..23) {
            my $res = $cb->(GET "/");
            $seen_pid{$res->content}++;
        }
        is keys(%seen_pid), 23, 'In Harakiri mode, each pid only used once';
        sleep 1;
    };

done_testing;
