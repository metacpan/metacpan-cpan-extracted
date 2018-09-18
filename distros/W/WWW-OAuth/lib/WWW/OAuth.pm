package WWW::OAuth;

use strict;
use warnings;

my %default_signer = (
	'PLAINTEXT' => \&_signer_plaintext,
	'HMAC-SHA1' => \&_signer_hmac_sha1,
);

use Class::Tiny::Chained qw(client_id client_secret token token_secret), {
	signature_method => 'HMAC-SHA1',
	signer => sub { $default_signer{$_[0]->signature_method} },
};

use Carp 'croak';
use Digest::SHA 'hmac_sha1_base64', 'sha1_hex';
use List::Util 'all', 'pairs', 'pairgrep';
use Scalar::Util 'blessed';
use URI;
use URI::Escape 'uri_escape_utf8';
use WWW::OAuth::Util 'oauth_request';

our $VERSION = '1.000';

sub authenticate {
	my $self = shift;
	my @req_args = ref $_[0] ? shift() : (shift, shift);
	my $req = oauth_request(@req_args);
	
	my $auth_header = $self->authorization_header($req, @_);
	
	$req->header(Authorization => $auth_header);
	return $req;
}

sub authorization_header {
	my $self = shift;
	my @req_args = ref $_[0] ? shift() : (shift, shift);
	my $req = oauth_request(@req_args);
	my $extra_params = shift;
	
	my ($client_id, $client_secret, $token, $token_secret, $signature_method, $signer) =
		($self->client_id, $self->client_secret, $self->token, $self->token_secret, $self->signature_method, $self->signer);
	
	croak 'Client ID and secret are required to generate authorization header'
		unless defined $client_id and defined $client_secret;
	
	croak "Signer is required for signature method $signature_method" unless defined $signer;
	
	if ($signature_method eq 'RSA-SHA1' and blessed $signer) {
		my $signer_obj = $signer;
		croak 'Signer for RSA-SHA1 must have "sign" method' unless $signer_obj->can('sign');
		$signer = sub { $signer_obj->sign($_[0]) };
	}
	croak "Signer for $signature_method must be a coderef" unless !blessed $signer and ref $signer eq 'CODE';
	
	my %oauth_params = (
		oauth_consumer_key => $client_id,
		oauth_nonce => _nonce(),
		oauth_signature_method => $signature_method,
		oauth_timestamp => time,
		oauth_version => '1.0',
	);
	$oauth_params{oauth_token} = $token if defined $token;
	
	# Extra parameters passed to authenticate()
	if (defined $extra_params) {
		croak 'OAuth parameters must be specified as a hashref' unless ref $extra_params eq 'HASH';
		croak 'OAuth parameters other than "realm" must all begin with "oauth_"'
		  unless all { $_ eq 'realm' or m/^oauth_/ } keys %$extra_params;
		%oauth_params = (%oauth_params, %$extra_params);
	}
	
	# This parameter is not allowed when creating the signature
	delete $oauth_params{oauth_signature};
	
	# Don't bother to generate signature base string for PLAINTEXT method
	my $base_str = $signature_method eq 'PLAINTEXT' ? '' : _signature_base_string($req, \%oauth_params);
	$oauth_params{oauth_signature} = $signer->($base_str, $client_secret, $token_secret);
	
	my $auth_str = join ', ', map { $_ . '="' . uri_escape_utf8($oauth_params{$_}) . '"' } sort keys %oauth_params;
	return "OAuth $auth_str";
}

sub _nonce { sha1_hex join '$', \my $dummy, time, $$, rand }

sub _signer_plaintext {
	my ($base_str, $client_secret, $token_secret) = @_;
	$token_secret = '' unless defined $token_secret;
	return uri_escape_utf8($client_secret) . '&' . uri_escape_utf8($token_secret);
}

sub _signer_hmac_sha1 {
	my ($base_str, $client_secret, $token_secret) = @_;
	$token_secret = '' unless defined $token_secret;
	my $signing_key = uri_escape_utf8($client_secret) . '&' . uri_escape_utf8($token_secret);
	my $digest = hmac_sha1_base64($base_str, $signing_key);
	$digest .= '='x(4 - length($digest) % 4) if length($digest) % 4; # Digest::SHA does not pad Base64 digests
	return $digest;
}

sub _signature_base_string {
	my ($req, $oauth_params) = @_;
	
	my @all_params = @{$req->query_pairs};
	push @all_params, map { ($_ => $oauth_params->{$_}) } grep { $_ ne 'realm' } keys %$oauth_params;
	push @all_params, @{$req->body_pairs} if $req->content_is_form;
	my @pairs = pairs map { uri_escape_utf8 $_ } @all_params;
	@pairs = sort { ($a->[0] cmp $b->[0]) or ($a->[1] cmp $b->[1]) } @pairs;
	my $params_str = join '&', map { $_->[0] . '=' . $_->[1] } @pairs;
	
	my $base_url = URI->new($req->url);
	$base_url->query(undef);
	$base_url->fragment(undef);
	return uc($req->method) . '&' . uri_escape_utf8($base_url) . '&' . uri_escape_utf8($params_str);
}

1;

=head1 NAME

WWW::OAuth - Portable OAuth 1.0 authentication

=head1 SYNOPSIS

 use WWW::OAuth;
 
 my $oauth = WWW::OAuth->new(
   client_id => $client_id,
   client_secret => $client_secret,
   token => $token,
   token_secret => $token_secret,
 );
 
 # Just retrieve authorization header
 my $auth_header = $oauth->authorization_header($http_request, { oauth_callback => $url });
 $http_request->header(Authorization => $auth_header);
 
 # HTTP::Tiny
 use HTTP::Tiny;
 my $res = $oauth->authenticate(Basic => { method => 'GET', url => $url })
   ->request_with(HTTP::Tiny->new);
 
 # HTTP::Request
 use HTTP::Request::Common;
 use LWP::UserAgent;
 my $res = $oauth->authenticate(GET $url)->request_with(LWP::UserAgent->new);
 
 # Mojo::Message::Request
 use Mojo::UserAgent;
 my $tx = $ua->build_tx(get => $url);
 $tx = $oauth->authenticate($tx->req)->request_with(Mojo::UserAgent->new);
 
=head1 DESCRIPTION

L<WWW::OAuth> implements OAuth 1.0 request authentication according to
L<RFC 5849|http://tools.ietf.org/html/rfc5849> (sometimes referred to as OAuth
1.0A). It does not implement the user agent requests needed for the complete
OAuth 1.0 authorization flow; it only prepares and signs requests, leaving the
rest up to your application. It can authenticate requests for
L<LWP::UserAgent>, L<Mojo::UserAgent>, L<HTTP::Tiny>, and can be extended to
operate on other types of requests.

Some user agents can be configured to automatically authenticate each request
with a L<WWW::OAuth> object.

 # LWP::UserAgent
 my $ua = LWP::UserAgent->new;
 $ua->add_handler(request_prepare => sub { $oauth->authenticate($_[0]) });
 
 # Mojo::UserAgent
 my $ua = Mojo::UserAgent->new;
 $ua->on(start => sub { $oauth->authenticate($_[1]->req) });

=head1 RETRIEVING ACCESS TOKENS

The process of retrieving access tokens and token secrets for authorization on
behalf of a user may differ among various APIs, but it follows this general
format (error checking is left as an exercise to the reader):

 use WWW::OAuth;
 use WWW::OAuth::Util 'form_urldecode';
 use HTTP::Tiny;
 my $ua = HTTP::Tiny->new;
 my $oauth = WWW::OAuth->new(
   client_id => $client_id,
   client_secret => $client_secret,
 );
 
 # Request token request
 my $res = $oauth->authenticate({ method => 'POST', url => $request_token_url },
   { oauth_callback => $callback_url })->request_with($ua);
 my %res_data = @{form_urldecode $res->{content}};
 my ($request_token, $request_secret) = @res_data{'oauth_token','oauth_token_secret'};
 
Now, the returned request token must be used to construct a URL for the user to
go to and authorize your application. The exact method differs by API. The user
will usually be redirected to the C<$callback_url> passed earlier after
authorizing, with a verifier token that can be used to retrieve the access
token and secret.
 
 # Access token request
 $oauth->token($request_token);
 $oauth->token_secret($request_secret);
 my $res = $oauth->authenticate({ method => 'POST', url => $access_token_url },
   { oauth_verifier => $verifier_token })->request_with($ua);
 my %res_data = @{form_urldecode $res->{content}};
 my ($access_token, $access_secret) = @res_data{'oauth_token','oauth_token_secret'};
 
Finally, the access token and secret can now be stored and used to authorize
your application on behalf of this user.

 $oauth->token($access_token);
 $oauth->token_secret($access_secret);

=head1 ATTRIBUTES

L<WWW::OAuth> implements the following attributes.

=head2 client_id

 my $client_id = $oauth->client_id;
 $oauth        = $oauth->client_id($client_id);

Client ID used to identify application (sometimes called an API key or consumer
key). Required for all requests.

=head2 client_secret

 my $client_secret = $oauth->client_secret;
 $oauth            = $oauth->client_secret($client_secret);

Client secret used to authenticate application (sometimes called an API secret
or consumer secret). Required for all requests.

=head2 token

 my $token = $oauth->token;
 $oauth    = $oauth->token($token);

Request or access token used to identify resource owner. Leave undefined for
temporary credentials requests (request token requests).

=head2 token_secret

 my $token_secret = $oauth->token_secret;
 $oauth           = $oauth->token_secret($token_secret);

Request or access token secret used to authenticate on behalf of resource
owner. Leave undefined for temporary credentials requests (request token
requests).

=head2 signature_method

 my $method = $oauth->signature_method;
 $oauth     = $oauth->signature_method($method);

Signature method, can be C<PLAINTEXT>, C<HMAC-SHA1>, C<RSA-SHA1>, or a custom
signature method. For C<RSA-SHA1> or custom signature methods, a L</"signer">
must be provided. Defaults to C<HMAC-SHA1>.

=head2 signer

 my $signer = $oauth->signer;
 $oauth     = $oauth->signer(sub {
   my ($base_str, $client_secret, $token_secret) = @_;
   ...
   return $signature;
 });

Coderef which implements the L</"signature_method">. A default signer is
provided for signature methods C<PLAINTEXT> and C<HMAC-SHA1>; this attribute is
required for other signature methods. For signature method C<RSA-SHA1>, this
attribute may also be an object which has a C<sign> method like
L<Crypt::OpenSSL::RSA>.

The signer is passed the computed signature base string, the client secret, and
(if present) the token secret, and must return the signature string.

=head1 METHODS

L<WWW::OAuth> implements the following methods.

=head2 authenticate

 $container = $oauth->authenticate($container, \%oauth_params);
 my $container = $oauth->authenticate($http_request, \%oauth_params);
 my $container = $oauth->authenticate(Basic => { method => 'GET', url => $url }, \%oauth_params);

Wraps the HTTP request in a container with L<WWW::OAuth::Util/"oauth_request">,
then sets the Authorization header using L</"authorization_header"> to sign the
request for OAuth 1.0. An optional hashref of OAuth parameters will be passed
through to L</"authorization_header">. Returns the container object.

=head2 authorization_header

 my $auth_header = $oauth->authorization_header($container, \%oauth_params);
 my $auth_header = $oauth->authorization_header($http_request, \%oauth_params);
 my $auth_header = $oauth->authorization_header(Basic => { method => 'GET', url => $url }, \%oauth_params);

Forms an OAuth 1.0 signed Authorization header for the passed request. As in
L</"authenticate">, the request may be specified in any form accepted by
L<WWW::OAuth::Util/"oauth_request">. OAuth protocol parameters (starting with
C<oauth_> or the special parameter C<realm>) may be optionally specified in a
hashref and will override any generated protocol parameters of the same name
(they should not be present in the request URL or body parameters). Returns the
signed header value.

=head1 HTTP REQUEST CONTAINERS

Request containers provide a unified interface for L</"authenticate"> to parse
and update HTTP requests. They must perform the L<Role::Tiny> role
L<WWW::OAuth::Request>. Custom container classes can be instantiated
directly or via L<WWW::OAuth::Util/"oauth_request">.

=head2 Basic

L<WWW::OAuth::Request::Basic> contains the request attributes directly, for
user agents such as L<HTTP::Tiny> that do not use request objects.

=head2 HTTP_Request

L<WWW::OAuth::Request::HTTP_Request> wraps a L<HTTP::Request> object, which
is compatible with several user agents including L<LWP::UserAgent>,
L<HTTP::Thin>, and L<Net::Async::HTTP>.

=head2 Mojo

L<WWW::OAuth::Request::Mojo> wraps a L<Mojo::Message::Request> object,
which is used by L<Mojo::UserAgent> via L<Mojo::Transaction>.

=head1 BUGS

Report any issues on the public bugtracker.

=head1 AUTHOR

Dan Book <dbook@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Dan Book.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=head1 SEE ALSO

L<Net::OAuth>, L<Mojolicious::Plugin::OAuth2>
