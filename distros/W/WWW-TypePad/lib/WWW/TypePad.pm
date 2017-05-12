package WWW::TypePad;
use strict;
use 5.008_001;

our $VERSION = '0.4002';

use Any::Moose;
use Carp qw( croak );
use HTTP::Request::Common;
use HTTP::Status;
use JSON;
use LWP::UserAgent;
use Net::OAuth::Simple;
use WWW::TypePad::Error;

# TODO import flag to preload them all
use WWW::TypePad::ApiKeys;
use WWW::TypePad::Applications;
use WWW::TypePad::Assets;
use WWW::TypePad::AuthTokens;
use WWW::TypePad::Blogs;
use WWW::TypePad::Events;
use WWW::TypePad::ExternalFeedSubscriptions;
use WWW::TypePad::Favorites;
use WWW::TypePad::Groups;
use WWW::TypePad::ImportJobs;
use WWW::TypePad::Relationships;
use WWW::TypePad::Users;

has 'consumer_key' => ( is => 'rw' );
has 'consumer_secret' => ( is => 'rw' );
has 'access_token' => ( is => 'rw' );
has 'access_token_secret' => ( is => 'rw' );
has 'host' => ( is => 'rw', default => 'api.typepad.com' );
has '_oauth' => ( is => 'rw' );

has 'ua' => (
    is      => 'rw',
    isa     => 'LWP::UserAgent',

    # All browsers must be an instance of an LWP::UserAgent, so that
    # we can guarantee that we can disable redirects.
    default => sub {
        my $ua = LWP::UserAgent->new;
        $ua->max_redirect( 0 );
        return $ua;
    },
    trigger => sub {
        my( $self, $ua, $attr ) = @_;
        $ua->max_redirect( 0 );
    },
);

sub oauth {
    my $api = shift;
    unless ( defined $api->_oauth ) {
        my $apikey = $api->get_apikey( $api->consumer_key );
        my $app = $apikey->{owner};

        my $oauth = Net::OAuth::Simple::AuthHeader->new(
            tokens => {
                consumer_key          => $api->consumer_key,
                consumer_secret       => $api->consumer_secret,
                access_token          => $api->access_token,
                access_token_secret   => $api->access_token_secret,
            },
            urls => {
                authorization_url   => $app->{oauthAuthorizationUrl},
                request_token_url   => $app->{oauthRequestTokenUrl},
                access_token_url    => $app->{oauthAccessTokenUrl},
            },
        );

        # Substitute our own LWP::UserAgent instance for the OAuth browser.
        $oauth->{browser} = $api->ua;

        $api->_oauth( $oauth );
    }
    return $api->_oauth;
}

sub get_apikey {
    my $api = shift;
    my( $key ) = @_;
    return $api->call_anon( GET => '/api-keys/' . $key . '.json' );
}

sub uri_for {
    my $api = shift;
    my( $path ) = @_;
    $path = '/' . $path unless $path =~ /^\//;
    return 'http://' . $api->host . $path;
}

sub call {
    my $api = shift;
    return $api->_call(0, @_);
}

sub call_anon {
    my $api = shift;
    return $api->_call(1, @_);
}

sub _call {
    my $api = shift;
    my( $anon, $method, $uri, $qs ) = @_;
    unless ( $uri =~ /^http/ ) {
        $uri = $api->uri_for( $uri );
    }
    if ( $method eq 'GET'&& $qs ) {
        $uri = URI->new( $uri );
        $uri->query_form( $qs );
    }
    my $res;
    if ( $api->access_token && !$anon ) {
        my %extra;
        if (($method eq 'POST' or $method eq 'PUT') and $qs) {
            $extra{ContentBody} = JSON::encode_json($qs);
            $extra{ContentType} = 'application/json';
        }

        my $oauth = $api->oauth;
        $res = $oauth->make_restricted_request( $uri, $method, %extra );
        
        if ( $res->is_redirect ) {
            $res = $oauth->make_restricted_request(
                $res->header( 'Location' ), $method, %extra
            );
        }
    } else {
        my $req = HTTP::Request->new( $method => $uri );
        $res = $api->ua->request( $req );
        
        if ( $res->is_redirect ) {
            $req = HTTP::Request->new( $method => $res->header( 'Location' ) );
            $res = $api->ua->request( $req );
        }
    }

    unless ( $res->is_success ) {
        WWW::TypePad::Error::HTTP->throw( $res->code, $res->content );
    }

    return 1 if $res->code == 204;
    return JSON::decode_json( $res->content );
}

sub call_upload {
    my $api = shift;
    my( $form ) = @_;

    croak "call_upload requires an access token"
        unless $api->access_token;

    my $target_uri = delete $form->{target_url}
        or croak "call_upload requires a target_url";

    my $filename = delete $form->{filename}
        or croak "call_upload requires a filename";

    my $asset = delete $form->{asset} || {};
    $asset = JSON::encode_json( $asset );

    my $uri = URI->new( $api->uri_for( '/browser-upload.json' ) );
    $uri->scheme( 'https' );

    # Construct the OAuth parameters to get a signature.
    my $nonce = Net::OAuth::Simple::AuthHeader->_nonce;
    my $oauth_req = Net::OAuth::ProtectedResourceRequest->new(
        consumer_key        => $api->consumer_key,
        consumer_secret     => $api->consumer_secret,
        token               => $api->access_token,
        token_secret        => $api->access_token_secret,
        request_url         => $uri->as_string,
        request_method      => 'POST',
        signature_method    => 'HMAC-SHA1',
        timestamp           => time,
        nonce               => $nonce,
    );
    $oauth_req->sign;

    # Send all of the OAuth parameters in the query string.
    $uri->query_form( $oauth_req->to_hash );

    # And now, construct the actual HTTP::Request object that contains
    # all of the fields we need to send.
    my $req = POST $uri,
        'Content-Type'  => 'multipart/form-data',
        Content         => [
            # Fake the redirect_to, since we just want to capture the
            # 302 response, and not actually follow the redirect.
            redirect_to             => 'http://example.com/none',

            target_url              => $target_uri,
            asset                   => $asset,
            file                    => [ $filename ],
        ];

    # The response to an upload is always a redirect; if it's anything
    # else, this indicates some internal error we weren't planning for,
    # so bail early.
    my $res = $api->ua->request( $req );
    unless ( $res->code == RC_FOUND && $res->header( 'Location' ) ) {
        WWW::TypePad::Error::HTTP->throw( $res );
    }

    # Otherwise, extract the response from the Location header. Successful
    # uploads will result in a status=201 query string parameter...
    my $loc = URI->new( $res->header( 'Location' ) );
    my %form = $loc->query_form;
    unless ( $form{status} == RC_CREATED ) {
        WWW::TypePad::Error::HTTP->throw( $form{status}, $form{error} );
    }

    # ... and an asset_url, which we can GET to get back an asset
    # dictionary.
    my $asset_uri = $form{asset_url};
    return $api->call_anon( GET => $asset_uri );
}

package Net::OAuth::Simple::AuthHeader;
# we need Net::OAuth::Simple to make requests with the OAuth credentials
# in an Authorization header, as required by the API, rather than the query string

use base qw( Net::OAuth::Simple );

sub make_restricted_request {
    my $self = shift;
    croak $Net::OAuth::Simple::UNAUTHORIZED unless $self->authorized;

    my( $url, $method, %extras ) = @_;
    # Use SSL.
    $url =~ s/^http:/https:/;

    my $uri = URI->new( $url );
    my %query = $uri->query_form;
    $uri->query_form( {} );

    $method = lc $method;

    my $content_body = delete $extras{ContentBody};
    my $content_type = delete $extras{ContentType};

    my $request = Net::OAuth::ProtectedResourceRequest->new(
        consumer_key     => $self->consumer_key,
        consumer_secret  => $self->consumer_secret,
        request_url      => $uri,
        request_method   => uc( $method ),
        signature_method => $self->signature_method,
        protocol_version => $self->oauth_1_0a ?
            Net::OAuth::PROTOCOL_VERSION_1_0A :
            Net::OAuth::PROTOCOL_VERSION_1_0,
        timestamp        => time,
        nonce            => $self->_nonce,
        token            => $self->access_token,
        token_secret     => $self->access_token_secret,
        extra_params     => { %query, %extras },
    );
    $request->sign;
    die "COULDN'T VERIFY! Check OAuth parameters.\n"
        unless $request->verify;

    my $request_url = URI->new( $url );

    my $req = HTTP::Request->new(uc($method) => $request_url);
    $req->header('Authorization' => $request->to_authorization_header);
    if ($content_body) {
        $req->content_type($content_type);
        $req->content_length(length $content_body);
        $req->content($content_body);
    }

    my $response = $self->{browser}->request($req);
    return $response;
}

1;
__END__

=encoding utf-8

=for stopwords

=head1 NAME

WWW::TypePad - Client for the TypePad Platform

=head1 SYNOPSIS

  use WWW::TypePad;
  my $tp = WWW::TypePad->new(
      consumer_key => 'YOUR-CONSUMER-KEY',
      consumer_secret => 'YOUR-CONSUMER-SECRET',
  );

  # See samples/debug-console/app.psgi for the OAuth authentication flow
  my $uid  = '6p0134842724af970c';
  my $user = $tp->users->get($uid);

  # See each modules POD documents for the API methods

=head1 DESCRIPTION

WWW::TypePad is a Perl library implementing an interface to the TypePad
API platform.

=head1 WARNINGS

B<The object interface and implementations are considered ALPHA and
will be likely to change in the future versions>.

=head1 AUTHOR

Benjamin Trott, Tatsuhiko Miyagawa and Martin Atkins E<lt>cpan@sixapart.comE<gt>

=head1 COPYRIGHT

Copyright 2010- Six Apart, Ltd.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 COMMUNITY

L<http://github.com/sixapart/perl-typepad-api>

=head1 SEE ALSO

L<http://developers.typepad.com/>
L<http://www.typepad.com/services/apidocs>

=cut
