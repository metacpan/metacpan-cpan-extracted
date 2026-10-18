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

note('up / down');
{
    my $http = Local::HTTP::Mock->new( ( Local::HTTP::Mock->ok ) x 5 );
    my $kuma = WebService::UptimeKuma::Push->new( url => $url, http => $http );

    ok( $kuma->up,                                                    'up returns true' );
    ok( $kuma->up( msg => 'hello world', ping => 7 ),                 'up with msg and ping returns true' );
    ok( $kuma->down( msg => 'disk full' ),                            'down with msg returns true' );
    ok( $kuma->up( ping => '0.125' ),                                 'up with fractional ping returns true' );
    ok( $kuma->up( msg => "K\x{fc}hlschrank & mehr", ping => undef ), 'up with non-ASCII msg returns true' );
    is( $kuma->error, undef, 'error is undef' );

    is_deeply(
        [ $http->urls ],
        [
            "$url?status=up",
            "$url?status=up&msg=hello%20world&ping=7",
            "$url?status=down&msg=disk%20full",
            "$url?status=up&ping=0.125",
            "$url?status=up&msg=K%C3%BChlschrank%20%26%20mehr",
        ],
        'correct URLs are requested',
    );
}

note('errors are returned');
{
    my $http = Local::HTTP::Mock->new(
        Local::HTTP::Mock->not_found,
        { success => q{}, status => 599, reason => 'Internal Exception', content => "Could not connect to 'kuma.example.net:443': Connection refused\n" },
        { success => q{}, status => 502, reason => 'Bad Gateway',        content => '<html>' },
        { success => 1,   status => 200, reason => 'OK',                 content => 'not json' },
        { die     => "something broke\n" },
        Local::HTTP::Mock->ok,
    );
    my $kuma = WebService::UptimeKuma::Push->new( url => $url, http => $http );

    ok( !$kuma->up, 'up returns false if the monitor does not exist' );
    is( $kuma->error, 'Monitor not found or not active.', '... error contains the message from Uptime Kuma' );

    ok( !$kuma->down, 'down returns false if the connection fails' );
    is( $kuma->error, q{Could not connect to 'kuma.example.net:443': Connection refused}, '... error contains the message from HTTP::Tiny' );

    ok( !$kuma->up, 'up returns false on a HTTP error' );
    is( $kuma->error, '502 Bad Gateway', '... error contains the HTTP status' );

    ok( !$kuma->up, 'up returns false on an unexpected response' );
    is( $kuma->error, 'Unexpected response from Uptime Kuma: 200 OK', '... error says so' );

    ok( !$kuma->up, 'up returns false if the http object dies' );
    is( $kuma->error, 'something broke', '... error contains the exception' );

    ok( $kuma->up, 'up returns true' );
    is( $kuma->error, undef, '... and error is reset' );
}

note('fatal');
{
    my $http = Local::HTTP::Mock->new( Local::HTTP::Mock->not_found, Local::HTTP::Mock->ok );
    my $kuma = WebService::UptimeKuma::Push->new( url => $url, http => $http, fatal => 1 );

    like( exception { $kuma->down }, qr{\QCannot push status 'down' to Uptime Kuma: Monitor not found or not active.\E}, 'down throws an exception with fatal' );
    is( $kuma->error, 'Monitor not found or not active.', '... and error is set' );
    ok( $kuma->up, 'up returns true' );
}

note('invalid arguments');
{
    my $kuma = WebService::UptimeKuma::Push->new( url => $url, http => Local::HTTP::Mock->new );

    like( exception { $kuma->up('hello') },            qr{\Qusage: up( [ARGS] )\E},                        'up throws an exception with an odd number of arguments' );
    like( exception { $kuma->down( ping => 'fast' ) }, qr{\Qping must be a non-negative number: 'fast'\E}, 'down throws an exception with an invalid ping' );
    like( exception { $kuma->up( ping => -1 ) },       qr{\Qping must be a non-negative number: '-1'\E},   'up throws an exception with a negative ping' );
    like( exception { $kuma->up( message => 'hi' ) },  qr{\QUnknown argument: 'message'\E},                'up throws an exception for an invalid argument' );
    like( exception { $kuma->up( a => 1, b => 2 ) },   qr{\QUnknown arguments: 'a', 'b'\E},                'up throws an exception for invalid arguments' );
}

#
done_testing();

exit 0;
