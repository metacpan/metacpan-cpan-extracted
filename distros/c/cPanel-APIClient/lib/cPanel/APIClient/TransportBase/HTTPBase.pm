package cPanel::APIClient::TransportBase::HTTPBase;

# Copyright 2020 cPanel, L. L. C.
# All rights reserved.
# http://cpanel.net
#
# This is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself. See L<perlartistic>.

use strict;
use warnings;

use parent qw( cPanel::APIClient::Transport );

my @_REQUIRED = ('hostname');

sub new {
    my ( $class, $authn, %opts ) = @_;

    if ( $authn->isa('cPanel::APIClient::Authn::Username') ) {
        die("HTTP-based transport $class doesn’t work with Username authentication.");
    }

    my @missing = grep { !defined $opts{$_} } @_REQUIRED;
    die( __PACKAGE__ . ": Missing @missing" ) if @missing;

    return bless {
        authn       => $authn,
        hostname    => $opts{'hostname'},
    }, $class;
}

sub _get_url_base {
    my ( $self, $service_obj ) = @_;

    my $url = "https://" . $self->{'hostname'};
    if ( my $port = $service_obj->get_https_port() ) {
        $url .= ":$port";
    }

    return $url;
}

sub _needs_session {
    my ($self) = @_;

    return $self->{'authn'}->needs_session();
}

sub _assemble_request_pieces {
    my ( $self, $service_obj, $request_obj ) = @_;

    my $method = $request_obj->get_http_method();

    my @headers = (
        $self->{'authn'}->get_http_headers_for_service($service_obj),
        $request_obj->get_http_headers(),
    );

    my $payload = $request_obj->get_http_payload();

    my $url = $self->_get_url_base($service_obj);
    $url .= $self->{'authn'}->get_url_path_prefix();
    $url .= $request_obj->get_http_url_path();

    return ( $method, $url, \@headers, $payload );
}

1;
