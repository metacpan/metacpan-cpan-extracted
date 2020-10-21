package TestHTTPWHM1Mixin;

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

use Test::More;
use Test::Deep;
use Test::Fatal;

use constant _CP_REQUIRE => (
    'MockCpsrvd::whm',
);

sub _set_up_whm : Tests(startup) {
    my ($self) = @_;

    my $server = MockCpsrvd::whm->new();
    $cPanel::APIClient::Service::whm::_PORT = $server->get_port();

    push @{ $self->{'_servers'} }, $server;

    return;
}

sub simple_whm_with_password : Tests(2) {
    my ($self) = shift;

    my $remote_cp = $self->CREATE(
        service => 'whm',

        credentials => {
            username  => 'johnny',
            password => 'mysecret',
        },
    );

    my $got = $self->AWAIT( $remote_cp->call_api1( 'do_something_warnings2_messages2' ) );

    cmp_deeply(
        $got,
        all(
            methods(
                [ isa => 'cPanel::APIClient::Response::WHM1' ] => bool(1),

                get_error => undef,

                get_data => {
                    content => q<api.version=1>,
                    method  => 'POST',
                    uri     => '/json-api/do_something_warnings2_messages2',
                    headers => ignore(),
                },

                get_nonfatal_messages   => bag(
                    [ info => 'message1' ],
                    [ info => 'message2' ],
                    [ warn => 'warn1' ],
                    [ warn => 'warn2' ],
                ),
            ),
        ),
        'WHM1 response',
    ) or diag explain $got;

    my %headers = @{ $got->get_data()->{'headers'} };

    cmp_deeply(
        \%headers,
        superhashof(
            {
                'Authorization' => 'Basic am9obm55Om15c2VjcmV0',
                'Content-Type'  => 'application/x-www-form-urlencoded',
            }
        ),
        'headers',
    ) or diag explain \%headers;

    return;
}

sub simple_whm_with_token : Tests(2) {
    my ($self) = shift;

    my $remote_cp = $self->CREATE(
        service => 'whm',

        credentials => {
            username  => 'johnny',
            api_token => 'MYTOKEN',
        },
    );

    my $got = $self->AWAIT( $remote_cp->call_api1( 'do_something_warnings1_messages1' ) );

    cmp_deeply(
        $got,
        all(
            methods(
                [ isa => 'cPanel::APIClient::Response::WHM1' ] => bool(1),

                get_error => undef,

                get_data                                       => {
                    content => q<api.version=1>,
                    method  => 'POST',
                    uri     => '/json-api/do_something_warnings1_messages1',
                    headers => ignore(),
                },

                get_nonfatal_messages   => bag(
                    [ info => 'message1' ],
                    [ info => 'message2' ],
                    [ warn => 'warn1' ],
                    [ warn => 'warn2' ],
                ),
            ),
        ),
        'WHM1 response',
    ) or diag explain $got;

    my %headers = @{ $got->get_data()->{'headers'} };

    cmp_deeply(
        \%headers,
        superhashof(
            {
                'Authorization' => 'whm johnny:MYTOKEN',
                'Content-Type'  => 'application/x-www-form-urlencoded',
            }
        ),
        'headers',
    ) or diag explain \%headers;

    return;
}

1;
