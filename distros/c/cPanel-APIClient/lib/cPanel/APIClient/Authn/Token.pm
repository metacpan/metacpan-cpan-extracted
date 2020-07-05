package cPanel::APIClient::Authn::Token;

# Copyright 2020 cPanel, L. L. C.
# All rights reserved.
# http://cpanel.net
#
# This is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself. See L<perlartistic>.

use strict;
use warnings;

use parent 'cPanel::APIClient::Authn';

sub new {
    my ( $class, $username, $token ) = @_;

    return bless [ $username, $token ], $class;
}

sub get_http_headers_for_service {
    my ( $self, $service_obj ) = @_;

    my $hdr_svc = $service_obj->service_name();    # TODO: check for whostmgr

    return [ Authorization => "$hdr_svc $self->[0]:$self->[1]" ];
}

1;
