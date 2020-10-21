package TestHTTPBase;

# Copyright 2020 cPanel, L. L. C.
# All rights reserved.
# http://cpanel.net
#
# This is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself. See L<perlartistic>.

use strict;
use warnings;
use autodie;

use parent 'TestBase';

use Test::More;

use Config;

use constant _CP_REQUIRE => (
    [ 'HTTP::Message' => 6.07 ],
    'HTTP::Request',
    'HTTP::Response',
    sub {
        die 'Need real fork!' if !$Config::Config{'d_fork'};
    },
);

sub TRANSPORT {
    my ($self) = @_;

    return [
        $self->TRANSPORT_PIECE(),
        hostname         => '127.0.0.1',    # “localhost” confuses Windows
        tls_verification => 'off',
    ];
}

sub runtests {
    my ($self) = shift;

    require cPanel::APIClient::Service::cpanel;
    local $cPanel::APIClient::Service::cpanel::_PORT;

    require cPanel::APIClient::Service::whm;
    local $cPanel::APIClient::Service::whm::_PORT;

    local $self->{'_servers'};

    return $self->SUPER::runtests();
}

sub _teardown_servers : Tests(shutdown) {
    my ($self) = shift;

    for ( splice @{$self->{'_servers'}} ) {
        diag sprintf( 'Tearing down server (%s) on port %d …', ref, $_->get_port() );
        $_->terminate();
    }

    return;
}

1;
