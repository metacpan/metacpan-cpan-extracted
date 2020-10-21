#!/usr/bin/env perl

# Copyright 2020 cPanel, L. L. C.
# All rights reserved.
# http://cpanel.net
#
# This is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself. See L<perlartistic>.

package t::mojouseragent;

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

use constant _CP_REQUIRE => (
    'Mojo::UserAgent',
    [ 'Mojolicious', '7.80' ],
    sub { diag "Using Mojolicious $Mojolicious::VERSION"; },
    sub {
        if ( $^V le v5.12.0 ) {
            die 'Avoiding pre-5.12 length(undef) warnings …';
        }
    },
);

sub TRANSPORT_PIECE {
    return ('MojoUserAgent');
}

sub AWAIT {
    my ( $self, $pending ) = @_;

    my ( $ok, $value, $reason );

    $pending->promise()->then(
        sub { $value = shift; $ok = 1 },
        sub { $reason = shift },
    )->wait();

    die $reason if !$ok;

    return $value;
}

1;
