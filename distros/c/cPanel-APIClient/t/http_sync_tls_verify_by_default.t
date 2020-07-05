#!/usr/bin/env perl

# Copyright 2020 cPanel, L. L. C.
# All rights reserved.
# http://cpanel.net
#
# This is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself. See L<perlartistic>.

package t::http_sync_tls_verify_by_default;

use strict;
use warnings;
use autodie;

use FindBin;
use lib "$FindBin::Bin/lib";

use parent (
    'TestHTTPBase',
    'TestHTTPTinyMixin',
);

use Test::More;
use Test::Deep;
use Test::Fatal;

__PACKAGE__->new()->runtests() if !caller;

#----------------------------------------------------------------------

# override TestHTTPBase’s default
sub TRANSPORT {
    my ($self) = @_;

    return [
        'HTTPSync',
        hostname => "localhost",
    ];
}

sub test_fail_because_tls : Tests(1) {
    my ($self) = @_;

    my $remote_cp = $self->CREATE(
        service => 'cpanel',

        credentials => {
            username  => 'johnny',
            api_token => 'MYTOKEN',
        },
    );

    my $err = exception {
        $self->AWAIT( $remote_cp->call_uapi( 'Doomed', 'noanswer' ) );
    };

    cmp_deeply(
        $err,
        all(
            Isa('cPanel::APIClient::X::SubTransport'),
            any(
                re( qr<ssl>i ),
                re( qr<tls>i ),
            ),
        ),
        'expected error object',
    );

    return;
}

1;
