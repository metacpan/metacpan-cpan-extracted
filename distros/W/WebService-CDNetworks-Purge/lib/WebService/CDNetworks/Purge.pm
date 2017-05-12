package WebService::CDNetworks::Purge;

use strict;
use warnings;

use 5.8.8;

=head1 NAME

WebService::CDNetworks::Purge - A client for the CDNetworks's Cache Flush Open API

=head1 SYNOPSIS

	my $service = WebService::CDNetworks::Purge -> new(
		'username' => 'xxxxxxxx',
		'password' => 'yyyyyyyy',
	);

	my $listOfPADs = $service -> listPADs();

	my $purgeStatus = $service -> purgeItems('test.example.com', ['/a.html', '/images/b.png']);

	my $updatedStatus = $service -> status($purgeStatus -> [0] -> {'pid'}); 

=cut

our $VERSION = '0.23'; # VERSION

use Carp;
use Try::Tiny;
use URI::Escape;
use JSON;
use LWP::UserAgent;

use Moose;

has 'baseURL' => (
	is       => 'ro',
	isa      => 'Str',
	default  => sub { 'https://openapi.us.cdnetworks.com/purge/rest' }
);

has 'ua' => (
	is       => 'ro',
	isa      => 'LWP::UserAgent',
	required => 1,
	lazy     => 1,
	default  => sub { LWP::UserAgent -> new() }
);

has 'username' => (
	is       => 'ro',
	isa      => 'Str',
	required => 1
);

has 'password' => (
	is       => 'ro',
	isa      => 'Str',
	required => 1
);

has 'pathsPerCall' => (
	is       => 'rw',
	isa      => 'Int',
	default  => sub { return 1000; },
);


=head1 METHODS

=cut

=head2 listPADs

Description: get the list of domains (or PADs) handled by user
Parameters: none
Returns: an array ref with the list of domains/PADs

=cut

sub listPADs {

	my ($self) = @_;

	my $requestPayload = {
		'output' => 'json',
		'user'   => $self -> username,
		'pass'   => $self -> password,
	};

	my $url = $self -> baseURL . '/padList';
	$url .= '?' . join '&', map { $_ . '=' . uri_escape($requestPayload -> {$_}) } keys %$requestPayload;

	my $ua = $self -> ua;
	$ua -> timeout(10);
	$ua -> env_proxy;

	my $response = $ua -> get($url);

	unless ($response -> is_success) {
		die $response -> status_line;
	}

	my $json = decode_json($response -> decoded_content);

	unless ($json -> {'resultCode'} && $json -> {'resultCode'} == 200) {
		die 'Invalid $json -> {resultCode}: ' . ($json -> {'resultCode'} || '<undef>');
	}

	return $json -> {'pads'};

}

# Description: private method used to purge a single chunk of paths from cache
# Parameters: PAD/domain and an arrayref with the list of paths to purge
# Returns: A hash ref with the parsed JSON response from service

sub _purgeItems {

	my ($self, $pad, $paths) = @_;

	my $requestPayload = {
		'output' => 'json',
		'user'   => $self -> username,
		'pass'   => $self -> password,
		'type'   => 'item',
		'pad'    => $pad,
		'path'   => $paths,
	};

	my $url = $self -> baseURL . '/doPurge';

	my $ua = $self -> ua;
	$ua -> timeout(10);
	$ua -> env_proxy;

	my $response = $ua -> post($url, $requestPayload);

	unless ($response -> is_success) {
		die $response -> status_line;
	}

	my $json = decode_json($response -> decoded_content);

	return $json;

}

=head2 purgeItems

Description: Purges for a certain PAD/domain a list of paths.
If the list is two long it is split and the service is called with each chunk of paths.
Parameters: PAD/domain and an arrayref with the list of paths to purge
Returns: An array ref with the list of responses for each pack of paths.

=cut

sub purgeItems {

	my ($self, $pad, $paths) = @_;

	unless ($pad) {
		croak 'No pad given!';
	}

	unless ($paths && ref($paths) && ref($paths) eq 'ARRAY') {
		croak 'Invalid paths given!';
	}

	if (scalar (@$paths) == 0) {
		carp 'Zero paths given!';
		return;
	}

	my $status;
	my $statuses = [];

	while (scalar (@$paths) > $self -> pathsPerCall) {
		my @payload = splice(@$paths, 0, $self -> pathsPerCall);
		$status = $self -> _purgeItems($pad, \@payload);
		push @$statuses, $status;
	}

	$status = $self -> _purgeItems($pad, $paths);
	push @$statuses, $status;

	return $statuses;

}

=head2 status

Description: Gets the current status of a certain purge request
Parameters: the purge request id
Returns: A hashref with the parsed JSON response from service

=cut

sub status {

	my ($self, $pid) = @_;

	my $requestPayload = {
		'output' => 'json',
		'user'   => $self -> username,
		'pass'   => $self -> password,
		'pid'    => $pid,
	};

	my $url = $self -> baseURL . '/status';
	$url .= '?' . join '&', map { $_ . '=' . uri_escape($requestPayload -> {$_}) } keys %$requestPayload;

	my $ua = $self -> ua;
	$ua -> timeout(10);
	$ua -> env_proxy;

	my $response = $ua -> get($url);

	unless ($response -> is_success) {
		die $response -> status_line;
	}

	my $json = decode_json($response -> decoded_content);

	unless ($json -> {'resultCode'} && $json -> {'resultCode'} == 200) {
		die 'Invalid $json -> {resultCode}: ' . ($json -> {'resultCode'} || '<undef>');
	}

	return $json;

}

=head1 AUTHOR

Jean Pierre Ducassou

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=head1 NO WARRANTY

This software is provided "as-is," without any express or implied warranty. In no event shall the author be held liable for any damages arising from the use of the software.

=cut

__PACKAGE__ -> meta -> make_immutable;
1;
