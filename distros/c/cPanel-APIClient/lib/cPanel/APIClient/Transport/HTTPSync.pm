package cPanel::APIClient::Transport::HTTPSync;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

cPanel::APIClient::Transport::HTTPSync - Synchronous HTTP transport

=head1 DESCRIPTION

This transport mechanism implements access to cPanel & WHM’s APIs
via synchronous (i.e., blocking) HTTP.

=head1 SEE ALSO

L<cPanel::APIClient::Transport::NetCurlPromiser> and
L<cPanel::APIClient::Transport::Mojolicious> facilitate sending
multiple concurrent API requests.

=cut

#----------------------------------------------------------------------

use parent qw(
  cPanel::APIClient::TransportBase::HTTPBase
  cPanel::APIClient::TransportBase::TLSVerificationBase
);

use HTTP::Tiny ();

use cPanel::APIClient::Utils::HTTPResponse ();

#----------------------------------------------------------------------

sub new {
    my ( $class, $authn, %opts ) = @_;

    my $self = $class->SUPER::new( $authn, %opts );

    my @ht_args;

    my $verify_SSL = ('off' ne $self->_parse_tls_verification( \%opts ) );

    push @ht_args, ( verify_SSL => $verify_SSL );

    if ( $self->_needs_session() ) {
        require HTTP::CookieJar;
        push @ht_args, ( cookie_jar => HTTP::CookieJar->new() );
    }

    $self->{'ua'} = HTTP::Tiny->new(@ht_args);

    return $self;
}

sub _get_session {
    my ( $self, $service_obj ) = @_;

    my ( $method, $url, $payload ) = $self->{'authn'}->get_login_request_pieces();
    substr( $url, 0, 0, $self->_get_url_base($service_obj) );

    die "Bad method: $method" if 'POST' ne $method;

    my $resp = $self->{'ua'}->post(
        $url,
        { content => $payload },
    );

    my $resp_obj = cPanel::APIClient::Transport::HTTPSync::Response->new($resp);

    $self->{'authn'}->consume_session_response($resp_obj);

    return;
}

sub request {
    my ( $self, $service_obj, $request_obj ) = @_;

    if ( $self->_needs_session() ) {
        $self->{'_got_session'} ||= do {
            $self->_get_session($service_obj);
            1;
        };
    }

    my ( $method, $url, $headers_ar, $payload ) = $self->_assemble_request_pieces( $service_obj, $request_obj );

    die "Bad method: $method" if 'POST' ne $method;

    my $resp = $self->{'ua'}->post(
        $url,
        {
            headers => { map { @$_ } @$headers_ar },
            content => $payload,
        },
    );

    if ( $resp->{'status'} == 599 ) {
        die $request_obj->create_transport_error( $resp->{'content'} );
    }

    my $resp_obj = cPanel::APIClient::Transport::HTTPSync::Response->new($resp);

    return $request_obj->parse_http_response( $resp_obj, $resp->{'content'} );
}

#----------------------------------------------------------------------

package cPanel::APIClient::Transport::HTTPSync::Response;

sub new {
    my ( $class, $struct ) = @_;

    return bless $struct, $class;
}

sub code {
    return $_[0]{'status'};
}

sub header {
    my ( $self, $name ) = @_;

    return $self->{'headers'}{$name};
}

sub as_string {
    my ($self) = @_;

    my $hdrs = $self->{'headers'};

    return join(
        "\x0d\x0a",
        join( q< >, grep { defined } @{$self}{ 'protocol', 'status', 'reason' } ),
        ( map { "$_: " . ( defined $hdrs->{$_} ? $hdrs->{$_} : q<> ) } keys %$hdrs ),
    );
}

=head1 LICENSE

Copyright 2020 cPanel, L. L. C. All rights reserved. L<http://cpanel.net>

This is free software; you can redistribute it and/or modify it under the
same terms as Perl itself. See L<perlartistic>.

=cut

1;
