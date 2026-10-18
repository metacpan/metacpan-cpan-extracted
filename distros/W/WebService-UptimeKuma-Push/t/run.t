#!perl

# vim: ts=4 sts=4 sw=4 et: syntax=perl
#
# Copyright (c) 2026 Sven Kirmess
#
# Permission to use, copy, modify, and distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

use 5.006;
use strict;
use warnings;

use Test::More 0.88;

use Cwd            ();
use File::Basename ();
use File::Spec     ();
use lib File::Spec->catdir( File::Basename::dirname( Cwd::abs_path __FILE__ ), 'lib' );

use Local::HTTP::Mock;
use Local::Test::Exception qw(exception);

use WebService::UptimeKuma::Push;

my $url = 'https://kuma.example.net/api/push/abc';

note('run( CODE ) succeeds');
{
    my $http = Local::HTTP::Mock->new( ( Local::HTTP::Mock->ok ) x 4 );
    my $kuma = WebService::UptimeKuma::Push->new( url => $url, http => $http );

    my @list = $kuma->run( sub { return qw(a b c) } );
    is_deeply( \@list, [qw(a b c)], 'run returns the list returned by the code in list context' );

    my $scalar = $kuma->run( sub { return wantarray ? 'list' : 'scalar' } );    ## no critic (Community::Wantarray)
    is( $scalar, 'scalar', 'run calls the code in scalar context' );

    my $called = 0;
    $kuma->run( sub { $called++; return; } );
    is( $called, 1, 'run calls the code in void context' );

    $kuma->run( sub { return }, msg => 'backup done' );

    my @urls = $http->urls;
    is( scalar @urls, 4, 'four heartbeats sent' );
    like( $urls[0], qr{\A\Q$url\E[?]status=up&ping=[0-9]+[.][0-9]{3}\z},                   'up with ping is sent' );
    like( $urls[3], qr{\A\Q$url\E[?]status=up&msg=backup%20done&ping=[0-9]+[.][0-9]{3}\z}, 'up with msg and ping is sent' );
}

note('run( CODE ) dies');
{
    my $http = Local::HTTP::Mock->new( ( Local::HTTP::Mock->ok ) x 2 );
    my $kuma = WebService::UptimeKuma::Push->new( url => $url, http => $http );

    is(
        exception {
            $kuma->run( sub { die "backup failed\n" } )
        },
        "backup failed\n",
        'run rethrows the exception',
    );

    my $obj = bless {}, 'Local::Exception';
    is(
        exception {
            $kuma->run( sub { die $obj; } )    ## no critic (ErrorHandling::RequireCarping)
        },
        $obj,
        'run rethrows exception objects',
    );

    my @urls = $http->urls;
    is( scalar @urls, 2, 'two heartbeats sent' );
    like( $urls[0], qr{\A\Q$url\E[?]status=down&msg=backup%20failed&ping=[0-9]+[.][0-9]{3}\z}, 'down with the exception as msg is sent' );
}

note('run( CODE ) dies and the heartbeat fails with fatal');
{
    my $http = Local::HTTP::Mock->new( Local::HTTP::Mock->not_found );
    my $kuma = WebService::UptimeKuma::Push->new( url => $url, http => $http, fatal => 1 );

    is(
        exception {
            $kuma->run( sub { die "backup failed\n" } )
        },
        "backup failed\n",
        'run rethrows the exception from the code',
    );
    is( $kuma->error, 'Monitor not found or not active.', '... and error is set' );
}

note('run( CODE ) succeeds and the heartbeat fails with fatal');
{
    my $http = Local::HTTP::Mock->new( Local::HTTP::Mock->not_found );
    my $kuma = WebService::UptimeKuma::Push->new( url => $url, http => $http, fatal => 1 );

    like(
        exception {
            $kuma->run( sub { return 1 } )
        },
        qr{\QCannot push status 'up' to Uptime Kuma: Monitor not found or not active.\E},
        'run throws an exception',
    );
}

note('invalid arguments');
{
    my $kuma = WebService::UptimeKuma::Push->new( url => $url, http => Local::HTTP::Mock->new );

    like( exception { $kuma->run }, qr{\Qusage: run( CODE, [ARGS] )\E}, 'run throws an exception without code' );
    like(
        exception {
            $kuma->run( sub { }, 'msg' )
        },
        qr{\Qusage: run( CODE, [ARGS] )\E},
        'run throws an exception with an odd number of arguments',
    );
    like(
        exception {
            $kuma->run( sub { }, ping => 7 )
        },
        qr{\QUnknown argument: 'ping'\E},
        'run throws an exception for an invalid argument',
    );
}

#
done_testing();

exit 0;
