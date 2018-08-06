package WebService::Hexonet::Connector;

use 5.026000;
use strict;
use warnings;
use WebService::Hexonet::Connector::Connection;

our $VERSION = '1.11';

sub connect {
    return WebService::Hexonet::Connector::Connection->new(@_);
}

1;

__END__

=head1 NAME

WebService::Hexonet::Connector - Connector library for the insanely fast L<HEXONET Backend API|https://www.hexonet.net/>.

=head1 SYNOPSIS

	###############################
	# How to use this Library?
	###############################

	# Install our module by
	cpan WebService::Hexonet::Connector
	# or
	cpanm WebService::Hexonet::Connector
	# NOTE: We suggest to use cpanm (App::cpanminus) for several reasons.


	use strict;
	use warnings;
	use WebService::Hexonet::Connector;

	# Create a connection with the URL, entity, login and password
	# Use "1234" as entity for the OT&E, and "54cd" for productive use
	# Don't have a Hexonet Account yet? Get one here: www.hexonet.net/sign-up
	my $api = WebService::Hexonet::Connector::connect({
		url => 'https://coreapi.1api.net/api/call.cgi',
		entity => '1234',
		login => 'test.user',
		password => 'test.passw0rd',
	});

	# Call a command
	my $response = $api->call({
		command => "querydomainlist",
		limit => 5
	});

	# Display the result in the format you want
	my $res = $response->as_list();
	$res = $response->as_list_hash();
	$res = $response->as_hash();

	# Get the response code and the response description
	my $code = $response->code();
	my $description = $response->description();

	print "$code $description";

=head1 DESCRIPTION

This module allows to query the API and to deal with different response formats (list, list_hash, hash).
It provides a short hand method (WebService::Hexonet::Connector::connect) to instantiate API clients.

A helper utility module is also included for tasks like date handling and string encoding.

=head1 AVAILABLE SUBMODULES

We've split our functionality into submodules to give this module a better structure.

=over 4

=item L<WebService::Hexonet::Connector::Connection> - API Client functionality.

=item L<WebService::Hexonet::Connector::Response> - API Response functionality.

=item L<WebService::Hexonet::Connector::Util> - Bundle of Helper methods.

=back

=head1 METHODS WebService::Hexonet::Connector

=over 4

=item C<connect(url, entity, login, password, user, role)>

Function connect Returns a Connection object connected to the API Server (URL, ENTITY, LOGIN, PASSWORD are mandatory to connect the server, ROLE ans USER are optional)

=back

=head1 AUTHOR

Hexonet GmbH

L<https://www.hexonet.net>

=head1 LICENSE

MIT

=cut
