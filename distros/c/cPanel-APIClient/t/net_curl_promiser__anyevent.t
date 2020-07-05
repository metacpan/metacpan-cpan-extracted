#!/usr/bin/env perl

# Copyright 2020 cPanel, L. L. C.
# All rights reserved.
# http://cpanel.net
#
# This is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself. See L<perlartistic>.

package t::net_curl_promiser__anyevent;

use strict;
use warnings;
use autodie;

use FindBin;
use lib "$FindBin::Bin/lib";

use parent (
    'TestHTTPBase',
    'TestHTTPUAPIMixin',
);

use Test::More;
use Test::Deep;
use Test::FailWarnings;

__PACKAGE__->new()->runtests() if !caller;

use constant _CP_REQUIRE => (
    'Net::Curl::Promiser::AnyEvent',
);

sub TRANSPORT_PIECE {
    my ($self) = @_;

    $self->{'_promiser'} ||= do {
        Net::Curl::Promiser::AnyEvent->new();
    };

    return ( 'NetCurlPromiser', promiser => $self->{'_promiser'} );
}

sub AWAIT {
    my ( $self, $pending ) = @_;

    my ( $ok, $value, $reason );

    my $cv = AnyEvent->condvar();
    $pending->promise()->then(
        sub { $value = shift; $ok = 1 },
        sub { $reason = shift },
    )->finally($cv);
    $cv->recv();

    die $reason if !$ok;

    return $value;
}

sub test_uapi_cancel : Tests(1) {
    my ($self) = @_;

  SKIP: {
        if ( !Net::Curl::Promiser->can('cancel_handle') ) {
            my $version = Net::Curl::Promiser->VERSION();
            skip "Net::Curl::Promiser $version lacks cancel_handle().", $self->num_tests();
        }

        # We don’t cancel() the request immediately because that’ll prompt
        # a connect warning in MockCpsrvd.pm. So instead we stop the event
        # loop on the first write, cancel the request, then resume the loop
        # so that the cancellation plays out “naturally”.

        my $cv1 = AnyEvent->condvar();

        local $cPanel::APIClient::Transport::NetCurlPromiser::_TWEAK_EASY_CR = sub {
            my ($easy) = @_;

            require Net::Curl::Easy;
            $easy->setopt(
                Net::Curl::Easy::CURLOPT_WRITEFUNCTION(),
                sub {
                    my ( $easy, $data, $uservar ) = @_;

                    $cv1->();

                    return length $data;
                }
            );
        };

        my $remote_cp = $self->CREATE(
            service => 'cpanel',

            credentials => {
                username  => 'johnny',
                api_token => 'MYTOKEN',
            },
        );

        my $pending = $remote_cp->call_uapi( 'Whatsit', 'heyhey' );

        my $reason;
        $pending->promise()->catch( sub { $reason = shift } );

        $cv1->recv();

        $remote_cp->cancel( $pending, 'beeecause' );

        my $cv2 = AnyEvent->condvar();

        $pending->promise()->catch( sub { } )->finally($cv2);
        $cv2->recv();

        cmp_deeply(
            $reason,
            all(
                Isa('cPanel::APIClient::X::SubTransport'),
                re(qr<beeecause>),
            ),
            'cancel() rejects the promise as expected',
        ) or diag explain $reason;
    }

    return;
}

1;
