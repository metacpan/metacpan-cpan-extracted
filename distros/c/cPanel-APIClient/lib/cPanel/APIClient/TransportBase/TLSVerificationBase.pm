package cPanel::APIClient::TransportBase::TLSVerificationBase;

# Copyright 2020 cPanel, L. L. C.
# All rights reserved.
# http://cpanel.net
#
# This is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself. See L<perlartistic>.

use strict;
use warnings;

sub _parse_tls_verification {
    my ( $self, $opts_hr ) = @_;

    if ( exists $opts_hr->{'tls_verification'} ) {
        my $tls_verification = delete $opts_hr->{'tls_verification'};

        if ( !grep { $_ eq $tls_verification } qw( on off ) ) {
            die "Bad “tls_verification”: $tls_verification";
        }

        $self->{'tls_verification'} = $tls_verification;
    }

    return $self->_get_tls_verification();
}

sub _get_tls_verification {
    my ($self) = @_;

    return $self->{'tls_verification'} || 'on';
}

1;
