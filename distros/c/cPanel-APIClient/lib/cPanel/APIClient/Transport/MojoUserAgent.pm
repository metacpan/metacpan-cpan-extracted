package cPanel::APIClient::Transport::MojoUserAgent;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

=head1 SYNOPSIS

    my $cp = cPanel::APIClient->create(
        service => 'cpanel',
        transport => [
            'MojoUserAgent',
            hostname => 'greathosting.net',

            # For testing only:
            # tls_verification => 'off',
        ],

        credentials => {
            username => 'hugh',
            api_token -> 'MYTOKEN',
        },
    );

=head1 DESCRIPTION

This module allows L<Mojo::UserAgent> to serve as transport
for asynchronous cPanel API calls.

It supports C<username>/C<password> or C<username>/C<api_token>
C<credentials> schemes. See L<cPanel::APIClient> for more details.

It expects these parameters:

=over

=item * C<hostname> - Required. The remote hostname that will serve
the API calls.

=item * C<tls_verification> - Optional. Either C<on> (default) or C<off>.

=back

=head1 SEE ALSO

L<cPanel::APIClient::Transport::NetCurlPromiser> can also integrate
with L<Mojolicious> but requires L<Net::Curl>, which you’ll need C compiler
access to install.

=cut

#----------------------------------------------------------------------

use parent qw(
  cPanel::APIClient::TransportBase::HTTPBase
  cPanel::APIClient::TransportBase::TLSVerificationBase
);

use Mojo::UserAgent ();

use cPanel::APIClient::Pending             ();
use cPanel::APIClient::Utils::HTTPResponse ();
use cPanel::APIClient::X                   ();

sub new {
    my ( $class, $authn, %opts ) = @_;

    my $self = $class->SUPER::new( $authn, %opts );

    $self->{'ua'} = Mojo::UserAgent->new();

    if ( 'off' eq $self->_parse_tls_verification( \%opts ) ) {
        $self->{'ua'}->insecure(1);
    }

    return $self;
}

sub _get_session_promise {
    my ( $self, $service_obj ) = @_;

    return $self->{'_session_promise'} ||= $self->_needs_session() && do {
        my ( $method, $url, $payload ) = $self->{'authn'}->get_login_request_pieces();
        substr( $url, 0, 0, $self->_get_url_base($service_obj) );

        die "Bad method: $method" if 'POST' ne $method;

        $self->{'ua'}->post_p(
            $url,
            {},
            $payload,
        )->then(
            sub {
                my ($tx) = @_;

                my $resp_obj = _tx2response($tx);

                $self->{'authn'}->consume_session_response($resp_obj);
            }
        );
    };
}

sub request {
    my ( $self, $service_obj, $request_obj ) = @_;

    my $make_promise_cr = sub {
        my ( $method, $url, $headers_ar, $payload ) = $self->_assemble_request_pieces( $service_obj, $request_obj );

        die "Bad method: $method" if 'POST' ne $method;

        my $promise = $self->{'ua'}->post_p(
            $url,
            { map { @$_ } @$headers_ar },
            $payload,
        )->then(
            sub {
                my ($tx) = @_;

                return _xform_tx( $request_obj, $tx );
            },
            sub {
                my ($why) = @_;

                die cPanel::APIClient::X->create( 'SubTransport', $why );
            },
        );
    };

    # XXX dedupe
    my $promise = $self->_get_session_promise($service_obj);
    $promise &&= $promise->then($make_promise_cr);
    $promise ||= $make_promise_cr->();

    # XXX How to cancel this?
    return cPanel::APIClient::Pending->new($promise);
}

sub _tx2response {
    my ($tx) = @_;

    my $code = $tx->res()->code();

    # This appears to be the easiest way to get this from Mojo …
    my $headers_str = $tx->res()->get_start_line_chunk(0) . $tx->res()->get_header_chunk(0);

    my $resp_obj = cPanel::APIClient::Utils::HTTPResponse->new( $code, $headers_str, $tx->res()->body() );

    return $resp_obj;
}

sub _xform_tx {
    my ( $request_obj, $tx ) = @_;

    my $resp_obj = _tx2response($tx);

    my $body = $tx->res()->body();

    return $request_obj->parse_http_response( $resp_obj, $body );
}

=head1 LICENSE

Copyright 2020 cPanel, L. L. C. All rights reserved. L<http://cpanel.net>

This is free software; you can redistribute it and/or modify it under the
same terms as Perl itself. See L<perlartistic>.

=cut

1;
