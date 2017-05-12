package WWW::Authy;
BEGIN {
  $WWW::Authy::AUTHORITY = 'cpan:GETTY';
}
{
  $WWW::Authy::VERSION = '0.002';
}
# ABSTRACT: Easy access to the already so easy Authy API


use MooX qw(
	+LWP::UserAgent
	+HTTP::Request::Common
	+URI
	+URI::QueryParam
	+JSON
);


use Carp qw( croak );

our $VERSION ||= '0.000';


has api_key => (
	is => 'ro',
	required => 1,
);


has sandbox => (
	is => 'ro',
	lazy => 1,
	builder => 1,
);

sub _build_sandbox { 0 }


has errors => (
	is => 'rw',
	predicate => 1,
	clearer => 1,
);


has base_uri => (
	is => 'ro',
	lazy => 1,
	builder => 1,
);

sub _build_base_uri {
	shift->sandbox
		? 'http://sandbox-api.authy.com'
		: 'https://api.authy.com'
}


has useragent => (
	is => 'ro',
	lazy => 1,
	builder => 1,
);

sub _build_useragent {
	my ( $self ) = @_;
	LWP::UserAgent->new(
		agent => $self->useragent_agent,
		$self->has_useragent_timeout ? (timeout => $self->useragent_timeout) : (),
	);
}


has useragent_agent => (
	is => 'ro',
	lazy => 1,
	builder => 1,
);

sub _build_useragent_agent { (ref $_[0] ? ref $_[0] : $_[0]).'/'.$VERSION }


has useragent_timeout => (
	is => 'ro',
	predicate => 'has_useragent_timeout',
);


has json => (
	is => 'ro',
	lazy => 1,
	builder => 1,
);

sub _build_json {
	my $json = JSON->new;
	$json->allow_nonref;
	return $json;
}

#############################################################################################################

sub BUILDARGS {
	my ( $class, @args ) = @_;
	unshift @args, "api_key" if @args % 2 && ref $args[0] ne 'HASH';
	return { @args };
}

sub make_url {
	my ( $self, @args ) = @_;
	my $url = join('/',$self->base_uri,'protected','json',@args);
	my $uri = URI->new($url);
	$uri->query_param( api_key => $self->api_key );
	return $uri;
}

sub new_user_request {
	my ( $self, $email, $cellphone, $country_code ) = @_;
	my $uri = $self->make_url('users','new');
	my @post = (
		'user[email]' => $email,
		'user[cellphone]' => $cellphone,
	);
	push @post, 'user[country_code]' => $country_code if $country_code;
	return POST($uri->as_string, [ @post ]);
}


sub new_user {
	my $self = shift;
	$self->clear_errors;
	my $response = $self->useragent->request($self->new_user_request(@_));
	my $data = $self->json->decode($response->content);
	if ($response->is_success) {
		return $data->{user}->{id};
	} else {
		$self->errors($data->{errors});
		return 0;
	}
}

sub verify_request {
	my ( $self, $id, $token ) = @_;
	my $uri = $self->make_url('verify',$token,$id);
	return GET($uri->as_string);
}


sub verify {
	my $self = shift;
	$self->clear_errors;
	my $response = $self->useragent->request($self->verify_request(@_));
	if ($response->is_success) {
		return 1;
	} else {
		my $data = $self->json->decode($response->content);
		$self->errors($data->{errors});
		return 0;
	}
}

sub sms_request {
	my ( $self, $id ) = @_;
	my $uri = $self->make_url('sms',$id);
	return GET($uri->as_string);
}


sub sms {
	my $self = shift;
	$self->clear_errors;
	my $response = $self->useragent->request($self->sms_request(@_));
	if ($response->is_success) {
		return 1;
	} else {
		my $data = $self->json->decode($response->content);
		$self->errors($data->{errors});
		return 0;
	}
}

1;


__END__
=pod

=head1 NAME

WWW::Authy - Easy access to the already so easy Authy API

=head1 VERSION

version 0.002

=head1 SYNOPSIS

  my $authy = WWW::Authy->new($authy_api_key);

  # email, cellphone, country code (optional)
  my $id = $authy->new_user('email@universe.org','555-123-2345','1');

  $authy->verify($id,$token) or print (Dumper $authy->errors);

  $authy->sms($id); # send sms for token

=head1 DESCRIPTION

This library gives an easy way to access the API of L<Authy|https://www.authy.com/> 2-factor authentification system.

=head1 ATTRIBUTES

=head2 api_key

API Key for the account given on the Account Settings

=head2 sandbox

Use the sandbox instead of the live system. This is off by default.

=head2 error

Gives back the error of the last request, if any given.

=head2 base_uri

Base of the URL of the Authy API, this is B<https://api.authy.com> without
sandbox mode, and B<http://sandbox-api.authy.com>, when the sandbox is
activated.

=head2 useragent

L<LWP::UserAgent> object used for the HTTP requests.

=head2 useragent_agent

The user agent string used for the L</useragent> object.

=head2 useragent_timeout

The timeout value in seconds used for the L</useragent> object, defaults to default value of
L<LWP::UserAgent>.

=head2 json

L<JSON> object used for JSON decoding.

=head1 METHODS

=head2 new_user

Takes the email, the cellphone number and optional the country code as
parameters and gives back the id for this user. Authy will generate the
user if he doesn't exist (verified by cellphone number), on a matching
entry it just gives back the existing user id.

=head2 verify

Verifies the first parameter as user id against the second parameter the token.
It gives back a true or a false value, it still could be another error then an
invalid token, so far this module doesnt differ.

=head2 sms

Send a SMS to the given user id. Please be aware that this may produce cost.
See the pricing on L<http://www.authy.com/pricing/> for more informations.

=head1 SUPPORT

IRC

  Join #duckduckgo on irc.freenode.net. Highlight Getty for fast reaction :).

Repository

  http://github.com/Getty/p5-www-authy
  Pull request and additional contributors are welcome

Issue Tracker

  http://github.com/Getty/p5-www-authy/issues

=head1 AUTHOR

Torsten Raudssus <torsten@raudss.us>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

