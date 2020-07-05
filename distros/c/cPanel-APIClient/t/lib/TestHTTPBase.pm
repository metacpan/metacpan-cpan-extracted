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

use constant _CP_REQUIRE => (
    [ 'HTTP::Message' => 6.07 ],
    'HTTP::Request',
    'HTTP::Response',
    'MockCpsrvd::cpanel',
);

sub TRANSPORT {
    my ($self) = @_;

    return [
        $self->TRANSPORT_PIECE(),
        hostname         => "localhost",
        tls_verification => 'off',
    ];
}

sub runtests {
    my ($self) = shift;

    require cPanel::APIClient::Service::cpanel;
    local $cPanel::APIClient::Service::cpanel::_PORT;

    local $self->{'_cpanel'};

    return $self->SUPER::runtests();
}

sub _set_up_servers : Tests(startup) {
    my ($self) = @_;

    $self->{'_cpanel'} = MockCpsrvd::cpanel->new();
    $cPanel::APIClient::Service::cpanel::_PORT = $self->{'_cpanel'}->get_port();

    return;
}

sub _teardown_servers : Tests(shutdown) {
    my ($self) = shift;

    for ( delete @{$self}{'_cpanel'} ) {
        diag sprintf( 'Tearing down server on port %d …', $_->get_port() );
        $_->terminate();
    }

    return;
}

1;
