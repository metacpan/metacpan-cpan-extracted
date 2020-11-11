package TestHTTPCpanelMixin;

# Copyright 2020 cPanel, L. L. C.
# All rights reserved.
# http://cpanel.net
#
# This is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself. See L<perlartistic>.

use strict;
use warnings;
use autodie;

use parent 'Test::Class';

use constant _CP_REQUIRE => (
    'MockCpsrvd::cpanel',
);

sub _set_up_servers : Tests(startup) {
    my ($self) = @_;

    my $server = MockCpsrvd::cpanel->new();
    $cPanel::APIClient::Service::cpanel::_PORT = $server->get_port();

    push @{ $self->{'_servers'} }, $server;

    return;
}

1;
