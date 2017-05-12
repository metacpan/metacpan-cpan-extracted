package WWW::Marvel::Client;
use strict;
use warnings;
use Carp;
use Digest::MD5;
use JSON;
use LWP::UserAgent;
use URI;

sub new {
	my ($class, $args) = @_;
	my $self = bless {}, $class;
	for my $k (qw/ private_key public_key /) {
		$self->{$k} = $args->{$k} if exists $args->{$k};
	}
	return $self;
}

sub get_private_key { $_[0]->{private_key} }
sub get_public_key  { $_[0]->{public_key} }
sub get_timestamp   { $_[0]->{timestamp} }
sub set_timestamp {
	my ($self, $timestamp) = @_;
	$self->{timestamp} = $timestamp;
	return $self;
}

sub get_endpoint    { "http://gateway.marvel.com" }
sub get_api_version { "v1" }

sub auth_query_params {
	my ($self) = @_;

	my $time = $self->get_timestamp || time;

	my %params = (
		ts     => $time,
		apikey => $self->get_public_key,
		hash   => $self->hash($time),
	);
	return \%params;
}

sub characters {
	my ($self, $params) = @_;
	my %p = %$params;
	my $uri = $self->uri({ path => 'characters', params => \%p });
	my $http_res = $self->get($uri);
	return $self->_get_json_content($http_res);
}

sub get {
	my ($self, $uri) = @_;
	my $attempts_limit = 3;
	my $http_res;
	while ($attempts_limit > 0) {
		$http_res = $self->ua->get($uri);
		last if $http_res->is_success;

		carp sprintf("Status line: '%s'", $http_res->status_line);
		$attempts_limit--;
		next if $attempts_limit && $http_res->status_line eq "500 read timeout";

		croak sprintf("Status line: '%s'\nReq: %s\nRes: %s",
			$http_res->status_line,
			$http_res->request->as_string,
			$http_res->as_string);
	}

	return $http_res;
}

# ref: https://developer.marvel.com/documentation/authorization
sub hash {
	my ($self, $time) = @_;

	if (!defined $time) {
		croak "need a timestamp to create a md5 hash" if !defined $self->get_timestamp;
		$time = $self->get_timestamp;
	}

	my $md5 = Digest::MD5->new;
	$md5->add( $time, $self->get_private_key, $self->get_public_key );
	return $md5->hexdigest;
}

sub _get_json_content {
	my ($self, $http_res) = @_;
	my $content = $self->json->decode( $http_res->decoded_content );
	return $content;
}

sub json { $_[0]->{_json} //= JSON->new()->allow_nonref->relaxed }

sub ua { $_[0]->{_ua} //= LWP::UserAgent->new() }

sub uri {
	my ($self, $args) = @_;


	my @paths;
	if (exists $args->{path} && ref $args->{path} eq 'ARRAY') {
		@paths = @{ $args->{path} };
	}
	elsif (exists $args->{path} && ref $args->{path} eq '') {
		push(@paths, $args->{path});
	}

	my %params;
	if (exists $args->{params} && ref $args->{params} eq 'HASH') {
		%params = %{ $args->{params} };
	}


	my $auth_query_params = $self->auth_query_params;
	my %query_params = ( %params, %$auth_query_params );

	my $uri = URI->new( $self->get_endpoint );
	$uri->path( $self->uri_path(@paths) );
	$uri->query_form(%query_params);

	return $uri;
}

sub uri_path {
	my ($self, @resources) = @_;
	croak "need a resource to query" if @resources < 1;
	return join('/', $self->get_api_version, 'public', @resources );
}

1;
