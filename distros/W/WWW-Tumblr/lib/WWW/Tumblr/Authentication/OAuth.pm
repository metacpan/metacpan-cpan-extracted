package WWW::Tumblr::Authentication::OAuth;

use strict;
use warnings;

use Carp;
use Moose;

use base 'WWW::Tumblr::Authentication';
extends 'WWW::Tumblr';

has 'authorize_url', is => 'rw', isa => 'Str', lazy => 1, default => sub {
	my $self = shift;
	croak "The consumer_key and secret_key must be defined!"
		unless $self->consumer_key && $self->secret_key;

	return $self->oauth->authorize_url();	
};

has 'oauth_token', is => 'rw', isa => 'Str';
has 'oauth_verifier', is => 'rw', isa => 'Str';

has 'token', is => 'rw', isa => 'Str', lazy => 1, default => sub{ shift->_get_token() };
has 'token_secret', is => 'rw', isa => 'Str', lazy => 1, default => sub { shift->_get_token('secret') };

has '_access_token', is => 'rw';

sub _get_token {
	my $self = shift;
	my $type = shift || 'token';

	croak "Cannot get OAuth token without 'oauth_token' and 'oauth_verifier' defined!"
		unless $self->oauth_token && $self->oauth_verifier;

	warn "Session looks empty, _get_token will fall, probably"
		unless keys %{ $self->_session };

	$self->_access_token( $self->oauth->get_access_token( $self->oauth_token, $self->oauth_verifier ) )
		unless $self->_access_token;

	return $type eq 'secret' ? $self->_access_token->token_secret : $self->_access_token->token;
}

1;
