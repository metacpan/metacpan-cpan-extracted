package cPanel::APIClient::Transport::NetCurlPromiser;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

cPanel::APIClient::Transport::NetCurlPromiser

=head1 SYNOPSIS

    my $promiser = Net::Curl::Promiser::AnyEvent->new();

    my $cp = cPanel::APIClient->create(
        service => 'cpanel',
        transport => [
            'NetCurlPromiser',
            promiser => $promiser,
            hostname => 'greathosting.net',

            # For testing only:
            # tls_verification => 'off',
        ],

        credentials => {
            username => 'hugh',
            password -> 'mySecretPassword!',
        },
    );

=head1 DESCRIPTION

This module allows L<Net::Curl::Promiser> (i.e.,
L<libcurl|https://curl.haxx.se/libcurl/> via L<Net::Curl>)
to serve as transport for cPanel API calls.

You can use this transport module to support any event interface that
Net::Curl::Promiser itself supports. See that module’s documentation
for more details.

It supports C<username>/C<password> or C<username>/C<api_token>
C<credentials> schemes. See L<cPanel::APIClient> for more details.

It expects these parameters:

=over

=item * C<promiser> - Required. Instance of a L<Net::Curl::Promiser>
subclass.

=item * C<hostname> - Required. The remote hostname that will serve
the API calls.

=item * C<tls_verification> - Optional. Either C<on> (default) or C<off>.

=back

This is probably the fastest way to call cPanel’s API via HTTP.

=head1 INTERFACE

When using this module, the immediate return from API-calling methods
(e.g., C<call_uapi()>) will be a L<cPanel::APIClient::Pending> instance.
See that module’s documentation for details of how to use it.

=head2 Cancellation

This class allows you to cancel an in-progress query, thus:

    $cp_service_obj->cancel($pending);

Note that the L<cPanel::APIClient::Pending> object’s promise will remain
pending indefinitely.

=cut

#----------------------------------------------------------------------

use parent qw(
  cPanel::APIClient::TransportBase::HTTPBase
  cPanel::APIClient::TransportBase::TLSVerificationBase
);

use Net::Curl::Easy ();

use cPanel::APIClient::Pending             ();
use cPanel::APIClient::Utils::HTTPResponse ();
use cPanel::APIClient::X                   ();

my @_REQUIRED = ('promiser');

#----------------------------------------------------------------------

sub new {
    my ( $class, $authn, %opts ) = @_;

    my $self = $class->SUPER::new( $authn, %opts );

    my @missing = grep { !defined $opts{$_} } @_REQUIRED;
    die( __PACKAGE__ . ": Missing @missing" ) if @missing;

    $self->{'promiser'} = $opts{'promiser'};

    $self->_parse_tls_verification( \%opts );

    if ( $self->_needs_session() ) {
        require Net::Curl::Share;
        $self->{'share'} = Net::Curl::Share->new();
        $self->{'share'}->setopt( Net::Curl::Share::CURLSHOPT_SHARE(), Net::Curl::Share::CURL_LOCK_DATA_COOKIE() );
    }

    return $self;
}

# for testing
our $_TWEAK_EASY_CR;

sub _create_easy {
    my ( $self, $method, $url, $payload ) = @_;

    die "Unsupported HTTP method: $method" if $method ne 'POST';

    my $easy = Net::Curl::Easy->new();

    if ( 'off' eq $self->_get_tls_verification() ) {
        $easy->setopt( Net::Curl::Easy::CURLOPT_SSL_VERIFYPEER, 0 );
        $easy->setopt( Net::Curl::Easy::CURLOPT_SSL_VERIFYHOST, 0 );
    }

    if ( $self->_needs_session() ) {
        $easy->setopt( Net::Curl::Easy::CURLOPT_COOKIEFILE, q<> );
        $easy->setopt( Net::Curl::Easy::CURLOPT_SHARE,      $self->{'share'} );
    }

    # We POST even if there’s no payload.
    $payload = q<> if !defined $payload;
    $easy->setopt( Net::Curl::Easy::CURLOPT_POSTFIELDSIZE,  length $payload );
    $easy->setopt( Net::Curl::Easy::CURLOPT_COPYPOSTFIELDS, $payload );

    $easy->setopt( Net::Curl::Easy::CURLOPT_URL, $url );

    @{$easy}{ 'head', 'body' } = ( q<>, q<> );

    $easy->setopt( Net::Curl::Easy::CURLOPT_HEADERDATA, \$easy->{'head'} );
    $easy->setopt( Net::Curl::Easy::CURLOPT_FILE,       \$easy->{'body'} );

    $_TWEAK_EASY_CR->($easy) if $_TWEAK_EASY_CR;

    return $easy;
}

sub _get_session_promise {
    my ( $self, $service_obj ) = @_;

    return $self->{'_session_promise'} ||= $self->_needs_session() && do {
        my ( $method, $url, $payload ) = $self->{'authn'}->get_login_request_pieces();
        substr( $url, 0, 0, $self->_get_url_base($service_obj) );

        my $session_easy = $self->_create_easy( $method, $url, $payload );

        $self->{'_session_easy'} = $session_easy;

        $self->{'promiser'}->add_handle($session_easy)->then(
            sub {
                my ($easy) = @_;

                my $resp_code = $easy->getinfo(Net::Curl::Easy::CURLINFO_RESPONSE_CODE);

                my $resp_obj = cPanel::APIClient::Utils::HTTPResponse->new(
                    $resp_code,
                    $easy->{'head'},
                );

                $self->{'authn'}->consume_session_response($resp_obj);
            }
        );
    };
}

sub request {
    my ( $self, $service_obj, $request_obj ) = @_;

    my $easy_sr = \do { my $v = undef };

    my $settled;

    my $get_promise_cr = sub {
        my ( $method, $url, $headers_ar, $payload ) = $self->_assemble_request_pieces( $service_obj, $request_obj );

        my $easy = $self->_create_easy( $method, $url, $payload );

        $$easy_sr = $easy;

        if (@$headers_ar) {
            my @header_strs = map { "$_->[0]: $_->[1]" } @$headers_ar;
            $easy->pushopt( Net::Curl::Easy::CURLOPT_HTTPHEADER, \@header_strs );
        }

        my $promise1 = $self->{'promiser'}->add_handle($easy);

        my $promise2 = $promise1->then(
            sub {
                return _xform_easy_response( $_[0], $request_obj );
            },
            sub {
                my ($code) = @_;
                my $str = "$code";

                die cPanel::APIClient::X->create( 'SubTransport', $str, code => $code );
            },
        );

        my $promise3 = $promise2->finally( sub {
            $settled = 1;
        } );

        return $promise3;
    };

    my $promise = $self->_get_session_promise($service_obj);
    $promise &&= $promise->then($get_promise_cr);
    $promise ||= $get_promise_cr->();

    return cPanel::APIClient::Pending->new( $promise, $easy_sr, \$settled );
}

sub _xform_easy_response {
    my ( $easy, $request_obj ) = @_;

    my $resp_code = $easy->getinfo(Net::Curl::Easy::CURLINFO_RESPONSE_CODE);

    my $resp_obj = cPanel::APIClient::Utils::HTTPResponse->new(
        $resp_code,
        $easy->{'head'},
        $easy->{'body'},
    );

    return $request_obj->parse_http_response( $resp_obj, $easy->{'body'} );
}

sub cancel {
    my ( $self, $pending_obj ) = @_;

    my ( $easy_sr, $settled_sr ) = $pending_obj->get_details();

    if ($$settled_sr) {
        die 'Request is already finished!';
    }

    if ( !$easy_sr ) {
        if ( $self->_needs_session() ) {
            $easy_sr = \$self->{'_session_easy'};
        }
        else {
            die 'non-session authn but session lacks detail!';
            die 'pending object lacks detail!';
        }
    }

    $self->{'promiser'}->cancel_handle($$easy_sr);

    return $self;
}

=head1 LICENSE

Copyright 2020 cPanel, L. L. C. All rights reserved. L<http://cpanel.net>

This is free software; you can redistribute it and/or modify it under the
same terms as Perl itself. See L<perlartistic>.

=cut

1;
