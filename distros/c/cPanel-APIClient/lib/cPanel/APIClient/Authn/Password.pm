package cPanel::APIClient::Authn::Password;

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
    my ( $class, $username, $password ) = @_;

    return bless [ $username, $password ], $class;
}

sub get_http_headers_for_service {
    my ( $self, $service_obj ) = @_;

    require MIME::Base64;

    my $b64 = MIME::Base64::encode( $self->[0] . ":" . $self->[1] );
    $b64 =~ tr<\x0d\x0a><>d;

    return [ Authorization => "Basic $b64" ];
}

1;
