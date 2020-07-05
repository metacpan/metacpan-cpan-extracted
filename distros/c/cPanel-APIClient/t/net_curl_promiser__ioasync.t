#!/usr/bin/env perl

# Copyright 2020 cPanel, L. L. C.
# All rights reserved.
# http://cpanel.net
#
# This is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself. See L<perlartistic>.

package t::net_curl_promiser__ioasync;

use strict;
use warnings;
use autodie;

use FindBin;
use lib "$FindBin::Bin/lib";

use parent (
    'TestHTTPBase',
    'TestHTTPUAPIMixin',
);

use Test::FailWarnings;

__PACKAGE__->new()->runtests() if !caller;

use constant _CP_REQUIRE => (
    'IO::Async::Loop',
    'Net::Curl::Promiser::IOAsync',
);

sub TRANSPORT_PIECE {
    my ($self) = @_;

    $self->{'_promiser'} ||= do {
        $self->{'_loop'} = IO::Async::Loop->new();
        Net::Curl::Promiser::IOAsync->new( $self->{'_loop'} );
    };

    return ( 'NetCurlPromiser', promiser => $self->{'_promiser'} );
}

sub AWAIT {
    my ( $self, $pending ) = @_;

    my ( $ok, $value, $reason );

    $pending->promise()->then(
        sub { $value = shift; $ok = 1 },
        sub { $reason = shift },
    )->finally( sub { $self->{'_loop'}->stop() } );

    $self->{'_loop'}->run();

    die $reason if !$ok;

    return $value;
}

1;
