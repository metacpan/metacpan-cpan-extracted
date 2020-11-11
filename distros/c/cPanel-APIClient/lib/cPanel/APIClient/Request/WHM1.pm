package cPanel::APIClient::Request::WHM1;

# Copyright 2020 cPanel, L. L. C.
# All rights reserved.
# http://cpanel.net
#
# This is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself. See L<perlartistic>.

use strict;
use warnings;

use parent qw( cPanel::APIClient::Request::HTTPBase );

use cPanel::APIClient::Utils::JSON    ();
use cPanel::APIClient::Response::WHM1 ();

sub HTTP_RESPONSE_CLASS { return 'cPanel::APIClient::Response::WHM1' }

sub new {
    my ( $class, $func, $args_hr, $metaargs_hr ) = @_;

    if ($metaargs_hr) {
        my %args_copy = %$args_hr;
        _parse_metaargs( $metaargs_hr, \%args_copy );
        $args_hr = \%args_copy;
    }

    return bless [ $func, $args_hr ], $class;
}

sub get_http_url_path {
    my ($self) = @_;

    return "/json-api/$self->[0]";
}

sub get_http_payload {
    my ($self) = @_;

    local $self->[1]{'api.version'} = 1;

    require cPanel::APIClient::Utils::HTTPRequest;
    return cPanel::APIClient::Utils::HTTPRequest::encode_form( $self->[1] );
}

#----------------------------------------------------------------------

sub get_cli_command {
    my ( $self, $authn ) = @_;

    my $username = $authn && $authn->username();

    require cPanel::APIClient::Utils::CLIRequest;
    return (
        '/usr/local/cpanel/bin/whmapi1',
        '--output=json',
        ( $username ? "--user=$username" : () ),
        $self->[0],
        cPanel::APIClient::Utils::CLIRequest::to_args( $self->[1] ),
    );
}

sub parse_cli_response {
    my ( $self, $resp_body ) = @_;

    my $resp_struct = cPanel::APIClient::Utils::JSON::decode($resp_body);
    return $self->HTTP_RESPONSE_CLASS()->new($resp_struct);
}

#----------------------------------------------------------------------

sub _parse_metaargs { die 'Unimplemented' }

1;
