use strict;
use warnings;

use Socket qw( AF_INET IPPROTO_TCP SOCK_STREAM inet_aton unpack_sockaddr_in );
use UV ();
use UV::Loop ();

use Test::More;

my $loop = UV::Loop->default;

{
    my $cb_called;

    # All-numerical lookup so should be nicely portable
    my $req = $loop->getaddrinfo( {
            node     => "12.34.56.78",
            service  => "1234",
            socktype => SOCK_STREAM,
        },
        sub {
            my ($status, @results) = @_;
            $cb_called++;

            cmp_ok($status, '==', 0, '$status is zero');
            is(scalar @results, 1, 'got 1 result');

            my $res = shift @results;
            is($res->family,   AF_INET,     '$res->family');
            is($res->socktype, SOCK_STREAM, '$res->socktype');

            # MSWin32 just reports zero here
            is($res->protocol, IPPROTO_TCP, '$res->protocol') unless $^O eq "MSWin32";

            is_deeply( [ unpack_sockaddr_in $res->addr ],
                       [ 1234, inet_aton("12.34.56.78") ],
                       '$res->addr' );
        }
    );
    isa_ok($req, 'UV::Req');
    $loop->run;
    ok($cb_called, 'getaddrinfo callback was called');
}

# $req->cancel
{
    my $cb_called;

    my $req = $loop->getaddrinfo( {
            node    => "1.2.3.4",
            service => "567",
        },
        sub {
            my ($status) = @_;
            $cb_called++;

            # These are inherently racy. libuv performs this lookup on a
            # worker thread which might have completed before we cancel it and
            # therefore it succeeds.
            return if $status == 0;

            # TODO: libuv docs claim this should be UV_CANCELED but in
            #   practice we observe UV_EAI_CANCELED
            cmp_ok($status, '==', UV::UV_EAI_CANCELED, '$status is cancelled');
        }
    );
    $req->cancel;
    $loop->run;
    ok($cb_called, 'callback was still called for cancelled request');
}

done_testing();
