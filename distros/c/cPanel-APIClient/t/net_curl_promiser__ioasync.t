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
    'TestHTTPWHM1Mixin',
);

use Test::More;

use Test::FailWarnings;

__PACKAGE__->new()->runtests() if !caller;

my $diagged;

use constant _CP_REQUIRE => (

    # Load NCP first because some Windows test runs produce spurious
    # warnings from IO::Async.
    'Net::Curl::Promiser::IOAsync',

    'IO::Async::Loop',

    [ 'Promise::ES6', '0.23' ],

    sub {
        $diagged++ or do {
            diag "Using libcurl " . Net::Curl::version();
            diag "Using Net::Curl $Net::Curl::VERSION";
            diag "Using Net::Curl::Promiser $Net::Curl::Promiser::VERSION";
            diag "Using IO::Async::Loop $IO::Async::Loop::VERSION";
        };
    },

);

sub runtests {
    no warnings 'once';
    local $IO::Async::Loop::LOOP = 'Select';

    return shift()->SUPER::runtests();
}

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

    my $loop = $self->{'_loop'};

    $pending->promise()->then(
        sub { $value = shift; $ok = 1 },
        sub { $reason = shift },
    )->finally( sub { $loop->stop() } );

    $loop->run();

    die $reason if !$ok;

    return $value;
}

1;
