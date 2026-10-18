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

use HTTP::Tiny;

require_ok( File::Spec->catfile( File::Basename::dirname( Cwd::abs_path __FILE__ ), File::Spec->updir, 'bin', 'kuma-push' ) ) or BAIL_OUT();

my $url = 'https://kuma.example.net/api/push/abc';

my @responses;
my @urls;
{
    no warnings 'redefine';    ## no critic (TestingAndDebugging::ProhibitNoWarnings)
    *HTTP::Tiny::get = sub {
        my ( $self, $get_url ) = @_;
        push @urls, $get_url;
        return shift @responses;
    };
}

sub main {
    my (@args) = @_;

    @urls = ();
    my $stderr = q{};

    my $rc;
    {
        local *STDERR;                                            ## no critic (Variables::RequireInitializationForLocalVars)
        open STDERR, '>', \$stderr or die "Cannot redirect STDERR: $!\n";
        $rc = WebService::UptimeKuma::Push::App::_main(@args);    ## no critic (Modules::RequireExplicitInclusion)
    }

    return $rc, $stderr, [@urls];
}

note('invalid usage');
{
    local $ENV{KUMA_PUSH_URL} = undef;

    my ( $rc, $stderr, $urls ) = main();
    is( $rc, 2, 'returns 2 without url' );
    like( $stderr, qr{\QNo push URL given. Use --url or set KUMA_PUSH_URL.\E}, '... prints an error' );
    like( $stderr, qr{\Qusage: \E},                                            '... prints usage' );
    is_deeply( $urls, [], '... sends nothing' );

    ( $rc, $stderr ) = main('--no-such-option');
    is( $rc, 2, 'returns 2 with an invalid option' );
    like( $stderr, qr{\Qusage: \E}, '... prints usage' );

    ( $rc, $stderr ) = main( '--url', $url, '--down', q{--}, $^X, q{-e}, '0' );
    is( $rc, 2, 'returns 2 with --down and a command' );

    ( $rc, $stderr ) = main( '--url', $url, '--ping', 7, q{--}, $^X, q{-e}, '0' );
    is( $rc, 2, 'returns 2 with --ping and a command' );

    ( $rc, $stderr ) = main( '--url', 'https://kuma.example.net/' );
    is( $rc, 2, 'returns 2 with an invalid url' );
    like( $stderr, qr{\QNot an Uptime Kuma push URL: 'https://kuma.example.net/'\E\n\z}, '... prints the error without location' );

    ( $rc, $stderr ) = main( '--url', $url, '--ping', 'fast' );
    is( $rc, 2, 'returns 2 with an invalid ping' );
    like( $stderr, qr{\Qping must be a non-negative number: 'fast'\E\n\z}, '... prints the error' );
}

note('heartbeat');
{
    local $ENV{KUMA_PUSH_URL} = undef;

    @responses = ( Local::HTTP::Mock->ok );
    my ( $rc, $stderr, $urls ) = main( '--url', $url );
    is( $rc,     0,   'returns 0' );
    is( $stderr, q{}, '... prints nothing' );
    is_deeply( $urls, ["$url?status=up"], '... sends up' );

    @responses = ( Local::HTTP::Mock->ok );
    ( $rc, $stderr, $urls ) = main( '--url', $url, '--down', '--msg', 'disk full', '--ping', '7', '--timeout', '3' );
    is( $rc, 0, 'returns 0' );
    is_deeply( $urls, ["$url?status=down&msg=disk%20full&ping=7"], '... sends down with msg and ping' );

    local $ENV{KUMA_PUSH_URL} = $url;
    @responses = ( Local::HTTP::Mock->not_found );
    ( $rc, $stderr, $urls ) = main();
    is( $rc, 1, 'returns 1 if the heartbeat fails' );
    like( $stderr, qr{\QCannot send heartbeat: Monitor not found or not active.\E}, '... prints the error' );
    is_deeply( $urls, ["$url?status=up"], '... uses KUMA_PUSH_URL' );
}

note('command');
{
    local $ENV{KUMA_PUSH_URL} = $url;

    @responses = ( Local::HTTP::Mock->ok );
    my ( $rc, $stderr, $urls ) = main( '--msg', 'done', q{--}, $^X, q{-e}, 'exit 0' );
    is( $rc,             0,   'returns 0 if the command succeeds' );
    is( $stderr,         q{}, '... prints nothing' );
    is( scalar @{$urls}, 1,   '... sends one heartbeat' );
    like( $urls->[0], qr{\A\Q$url\E[?]status=up&msg=done&ping=[0-9]+[.][0-9]{3}\z}, '... up with msg and ping' );

    @responses = ( Local::HTTP::Mock->ok );
    ( $rc, $stderr, $urls ) = main( '--msg', 'done', $^X, q{-e}, 'exit 3' );
    is( $rc, 3, 'returns the exit code of the command, also without --' );
    like( $stderr,    qr{\Qexited with 3\E},                                                               '... prints the reason' );
    like( $urls->[0], qr{\A\Q$url\E[?]status=down&msg=[^&]+%20exited%20with%203&ping=[0-9]+[.][0-9]{3}\z}, '... sends down' );

    @responses = ( Local::HTTP::Mock->not_found );
    ( $rc, $stderr, $urls ) = main( q{--}, $^X, q{-e}, 'exit 0' );
    is( $rc, 0, 'returns the exit code of the command if the heartbeat fails' );
    like( $stderr, qr{\QCannot send heartbeat: Monitor not found or not active.\E}, '... prints the error' );

    my $missing = File::Spec->catfile( File::Basename::dirname( Cwd::abs_path __FILE__ ), 'no-such-command' );
    @responses = ( Local::HTTP::Mock->ok );
    ( $rc, $stderr, $urls ) = main( q{--}, $missing );
    if ( $^O eq 'MSWin32' ) {

        # On Windows, system() does not return -1 for a missing command,
        # the command is reported as exited with 255 instead.
        is( $rc, 255, 'returns 255 if the command cannot be run' );
        like( $stderr,    qr{\Qexited with 255\E},                                       '... prints the reason' );
        like( $urls->[0], qr{\A\Q$url\E[?]status=down&msg=[^&]+%20exited%20with%20255&}, '... sends down' );
    }
    else {
        is( $rc, 127, 'returns 127 if the command cannot be run' );
        like( $stderr,    qr{\QCannot run $missing:\E},                     '... prints the reason' );
        like( $urls->[0], qr{\A\Q$url\E[?]status=down&msg=Cannot%20run%20}, '... sends down' );
    }

  SKIP: {
        skip 'signals are not supported on Windows', 2 if $^O eq 'MSWin32';

        @responses = ( Local::HTTP::Mock->ok );
        ( $rc, $stderr, $urls ) = main( q{--}, $^X, q{-e}, 'kill 9, $$' );
        is( $rc, 128 + 9, 'returns 128 + signal if the command is killed' );
        like( $stderr, qr{\Qdied with signal 9\E}, '... prints the reason' );
    }
}

#
done_testing();

exit 0;
