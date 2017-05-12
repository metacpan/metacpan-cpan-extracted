package Test::Override::UserAgent;

use 5.008001;
use strict;
use warnings 'all';

###########################################################################
# METADATA
our $AUTHORITY = 'cpan:DOUGDUDE';
our $VERSION   = '0.004001';

###########################################################################
# MODULE IMPORTS
use Carp qw(croak);
use Clone;
use HTTP::Config 5.815;
use HTTP::Date ();
use HTTP::Headers;
use HTTP::Response;
use HTTP::Status 5.817 ();
use LWP::UserAgent; # Not actually required here, but want it to be loaded
use Scalar::Util;
use Sub::Install 0.90;
use Test::Override::UserAgent::Scope;
use Try::Tiny;
use URI;

###########################################################################
# ALL IMPORTS BEFORE THIS WILL BE ERASED
use namespace::clean 0.04 -except => [qw(meta)];

###########################################################################
# METHODS
sub allow_live_requests {
	my ($self, $new_value) = @_;

	if (defined $new_value) {
		# Set the new value
		$self->{allow_live_requests} = $new_value;
	}

	return $self->{allow_live_requests};
}
sub handle_request {
	my ($self, $request, %args) = @_;

	# Lookup the handler for the request
	my $handler = $self->_get_handler_for($request);

	# Hold the response
	my $response;

	if (defined $handler) {
		# Get the response
		$response = _convert_psgi_response($handler->($request));

		if (!defined $response->request) {
			# Set the request that made this response
			$response->request($request);
		}
	}

	if (!defined $response && exists $args{live_request_handler}) {
		# There was no handler/response and a live requestor was provided
		if ($self->allow_live_requests) {
			# Make the live request
			$response = $args{live_request_handler}->($request);
		}
		else {
			# Make an internal response for not successful since no
			# live requests are allowed.
			$response = _new_internal_response(
				HTTP::Status::HTTP_NOT_FOUND,
				'Not Found (No Live Requests)',
			);
		}
	}

	return $response;
}
sub install_in_scope {
	my ($self) = @_;

	# Return the scope variable
	return Test::Override::UserAgent::Scope->new(
		override => $self,
	);
}
sub install_in_user_agent {
	my ($self, $user_agent, %args) = @_;

	# Get the clone argument
	my $clone = exists $args{clone} ? $args{clone} : 0;

	if ($clone) {
		# Make a clone of the user agent
		$user_agent = $user_agent->clone;
	}

	# Add as a handler in the user agent
	$user_agent->add_handler(
		request_send => sub {
			# Get the response
			my $response = $self->handle_request(
				shift,
				live_request_handler => sub { return; },
			);

			return $response;
		},
		owner => Scalar::Util::refaddr($self),
	);

	# Return the user agent
	return $user_agent;
}
sub override_request {
	my ($self, @args) = @_;

	# Get the handler from the end
	my $handler = pop @args;

	# Convert the arguments into a hash
	my %args = @args;

	# Register the handler
	$self->_register_handler($handler, %args);

	# Enable chaining
	return $self;
}
sub uninstall_from_user_agent {
	my ($self, $user_agent) = @_;

	# Remove our handlers from the user agent
	$user_agent->remove_handler(
		'request_send',
		owner => Scalar::Util::refaddr($self),
	);

	# Return the user agent for some reason
	return $user_agent;
}

###########################################################################
# STATIC METHODS
sub import {
	my ($class, %args) = @_;

	# What this module is being used for
	my $use_for = $args{for} || 'testing';

	if ($use_for eq 'configuration') {
		# Get the calling package
		my $caller = caller;

		# Create a new configuration object that will be wrapped in
		# closures.
		my $conf = $class->new;

		# Create a defaults hash for colsures
		my $defaults = {};

		# Install override_request
		Sub::Install::install_sub({
			code => sub { return $conf->override_request(%{$defaults}, @_); },
			into => $caller,
			as   => 'override_request',
		});

		# Install override_for
		Sub::Install::install_sub({
			code => sub {
				my $block = pop;

				# Rember the current defaults
				my $previous_defaults = $defaults;

				# Set the new defaults as an extension of the current
				$defaults = {%{Clone::clone($defaults)}, @_};

				# Run the block with the defaults in effect
				$block->();

				# Restore the defaults
				$defaults = $previous_defaults;
			},
			into => $caller,
			as   => 'override_for',
		});

		# Install allow_live
		Sub::Install::install_sub({
			code => sub {
				my $allow = shift;

				# Set the allow live requests (no arguments defaults to 1)
				$conf->allow_live_requests(defined $allow ? $allow : 1);
			},
			into => $caller,
			as   => 'allow_live',
		});

		# Install custom configuration which retuns the config object
		Sub::Install::install_sub({
			code => sub { return $conf; },
			into => $caller,
			as   => 'configuration',
		});
	}

	return;
}

###########################################################################
# CONSTRUCTOR
sub new {
	my ($class, @args) = @_;

	# Get the arguments as a plain hash
	my %args = @args == 1 ? %{shift @args}
	                      : @args
	                      ;

	# Create a hash with configuration information
	my %data = (
		# Attributes
		allow_live_requests => 0,

		# Private attributes
		_lookup_table => HTTP::Config->new,
		_protocol_classes => {},
	);

	# Set attributes
	foreach my $arg (grep { m{\A [^_]}msx } keys %data) {
		if (exists $args{$arg}) {
			$data{$arg} = $args{$arg};
		}
	}

	# Bless the hash to this class
	my $self = bless \%data, $class;

	# Set our unique name
	$self->{_uniq_name} = $class . '::Number' . Scalar::Util::refaddr($self);

	# Return our blessed configuration
	return $self;
}

###########################################################################
# PRIVATE METHODS
sub _get_handler_for {
	my ($self, $request) = @_;

	# Get the handler
	my @handlers = $self->{_lookup_table}->matching_items($request);

	return $handlers[0];
}
sub _register_handler {
	my ($self, $handler, %args) = @_;

	# Add m_ to the beginning of the arguments
	for my $key (keys %args) {
		# Specially handle "url" key as HTTP::Config does not
		if ($key eq 'url' || $key eq 'uri') {
			# Get the URI from the arguments
			my $uri = URI->new(delete $args{$key});

			# Set a match against it's canonical value
			$args{m_uri__canonical} = $uri->canonical;
		}
		elsif (q{m_} ne substr $key, 0, 2) {
			# Add m_
			$args{"m_$key"} = delete $args{$key};
		}
	}

	# Set the handler
	$self->{_lookup_table}->add_item($handler, %args);

	return;
}

###########################################################################
# PRIVATE FUNCTIONS
sub _convert_psgi_response {
	my ($response) = @_;

	if (!defined Scalar::Util::blessed($response)) {
		# Get the type of the response
		my $response_type = Scalar::Util::reftype($response);

		if (defined $response_type && $response_type eq 'ARRAY') {
			# This is a PSGI-formatted response
			try {
				# Validate the response
				_validate_psgi_response($response);

				# Unwrap the PSGI response
				my ($status_code, $headers, $body) = @{$response};

				# Change the headers to a header object
				$headers = HTTP::Headers->new(@{$headers});

				if (ref $body ne 'ARRAY') {
					# The body is a filehandle
					my $fh = $body;

					# Change the body to an array reference
					$body = [];

					while (defined(my $line = $fh->getline)) {
						# Push the line into the body
						push @{$body}, $line;
					}

					# Close the file
					$fh->close;
				}

				# Create the response object
				$response = HTTP::Response->new(
					$status_code, undef, $headers, join q{}, @{$body});
			}
			catch {
				# Invalid PSGI response
				my $error = "$_"; # stringify error

				# Remove line information from croak
				$error =~ s{\s at \s .+ \z}{}msx;

				# Set the response
				$response = _new_internal_response(
					HTTP::Status::HTTP_EXPECTATION_FAILED,
					$error,
				);
			};
		}
		else {
			# Bad return value from handler
			$response = _new_internal_response(
				HTTP::Status::HTTP_EXPECTATION_FAILED,
				'Override handler returned invalid value: ' . $response
			);
		}
	}

	return $response;
}
sub _is_invalid_psgi_header_key {
	my ($key) = @_;

	return $key =~ m{(?:\A status \z | [:\n] | [_-] \z)}imsx
		|| $key !~ m{\A [a-z] [a-z0-9_-]* \z}imsx;
}
sub _is_invalid_psgi_header_value {
	my ($value) = @_;

	return ref $value ne q{} || $value =~ m{[\x00-\x19\x21-\x25]}imsx;
}
sub _new_internal_response {
	my ($code, $message) = @_;

	# Make a new response
	my $response = HTTP::Response->new($code, $message);

	# Set some headers for client information
	$response->header(
		'Client-Date'            => HTTP::Date::time2str(time),
		'Client-Response-Source' => __PACKAGE__,
		'Client-Warning'         => 'Internal response',
		'Content-Type'           => 'text/plain',
	);

	# Set the content as the status_line
	$response->content("$code $message");

	return $response;
}
sub _validate_psgi_response {
	my ($psgi) = @_;

	# Unwrap the response
	my ($code, $headers, $body) = @{$psgi};

	if ($code !~ m{\A [1-9] \d{2,} \z}msx) {
		croak 'PSGI HTTP status code MUST be 100 or greater';
	}

	if (ref $headers ne 'ARRAY') {
		croak 'PSGI headers MUST be an array reference';
	}

	if (@{$headers} % 2 != 0) {
		croak 'PSGI headers MUST have even number of elements';
	}

	# Headers copied
	my @headers = @{$headers};

	# Hold invalid stuff
	my (@invalid_header_keys, @invalid_header_values,
		$has_content_type, $has_content_length);

	while (my ($key, $value) = splice @headers, 0, 2) {
		if (_is_invalid_psgi_header_key($key)) {
			# Remember the invalid key
			push @invalid_header_keys, $key;
		}
		elsif (lc $key eq 'content-type') {
			# The response has a defined content type
			$has_content_type = 1;
		}
		elsif (lc $key eq 'content-length') {
			# The response has a defined content length
			$has_content_length = 1;
		}

		if (_is_invalid_psgi_header_value($value)) {
			# Remember the key of the invalid value
			push @invalid_header_values, $key;
		}
	}

	if (@invalid_header_keys) {
		croak 'PSGI headers have invalid key(s): ',
			join q{, }, sort @invalid_header_keys;
	}

	if (@invalid_header_values) {
		croak 'PSGI headers have invalid value(s): ',
			join q{, }, sort @invalid_header_values;
	}

	if (!$has_content_type && $code !~ m{\A 1 | [23]04}msx) {
		croak 'There MUST be a Content-Type for code other than 1xx, 204, and 304';
	}

	if ($has_content_length && $code =~ m{\A 1 | [23]04}msx) {
		croak 'There MUST NOT be a Content-Length for 1xx, 204, and 304';
	}

	# Return true for successful check
	return 1;
}

1;

__END__

=head1 NAME

Test::Override::UserAgent - Override the LWP::UserAgent to return canned responses for testing

=head1 VERSION

This documentation refers to version 0.004001

=head1 SYNOPSIS

  package Test::My::Module::UserAgent::Configuration;

  # Load into configuration module
  use Test::Override::UserAgent for => 'configuration';

  # Allow unhandled requests to be live
  allow_live;

  override_request path => '/test.html', sub {
      my ($request) = @_;

      # Do something with request and make HTTP::Response

      return $response;
  };

  package main;

  # Load the module
  use Test::My::Module::UserAgent::Configuration;

  my $scope = Test::My::Module::UserAgent::Configuration
      ->configuration->install_in_scope;

=head1 DESCRIPTION

This module allows for very easy overriding of the request-response cycle of
L<LWP::UserAgent|LWP::UserAgent> and any other module extending it. The
override can be done per-scope (where the API of a module doesn't let you
alter it's internal user agent object) or per-object, but modifying the
user agent.

=head1 IMPORTING

This module take a HASH of arguments to the C<import> method that specify how
this module will alter the symbol table of the package calling the C<import>
method. Without any arguments supplied, this module will not alter the symbol
table. The following keys are accepted:

=over 4

=item for

This specifies the reason this module is being imported into the calling
package. The value for this is a string. By default the value is C<testing>
which specifies the module is for testing purposes and will not import
anything. The other option is C<configuration> which imports several symbols
and sets up the calling package to be a configuration package. For details
about making a configuration package, see
L<Test::Override::UserAgent::Manual::ConfigurationPackage|Test::Override::UserAgent::Manual::ConfigurationPackage>.

=back

=head1 CONSTRUCTOR

=head2 new

This will construct a new configuration object to allow for configuring user
agent overrides.

=over 4

=item B<new(%attributes)>

C<%attributes> is a HASH where the keys are attributes (specified in the
L</ATTRIBUTES> section).

=item B<new($attributes)>

C<$attributes> is a HASHREF where the keys are attributes (specified in the
L</ATTRIBUTES> section).

=back

=head1 ATTRIBUTES

=head2 allow_live_requests

This is a Boolean specifying if the user agent is allowed to make any live
requests (so allowing it to make requests that are not overwritten). The
default is C<0> which causes any requests made to a location that has not
been overwritten to return an appropriate HTTP request as if the overwritten
responses are the entire Internet.

=head1 METHODS

=head2 handle_request

The first argument is a L<HTTP::Request object|HTTP::Request>. The rest of
the arguments are a hash (not a hash reference) with the keys specified
below. This will return either a L<HTTP::Request|HTTP::Response> if the
request had a corresponding override or C<undef> if no override was present
to handle the request. Unless the C<live_request_handler> was specified,
which changes what is returned (see below).

=over 4

=item live_request_handler

This takes a code reference that will be called if it is determined that the
request should be live. The code is given one argument: the request object that
was given to L</handle_request>. If this argument is given, then if it is
determined that live requests are not permitted, L</handle_request> will no
longer return C<undef> and will instead return a
L<HTTP::Response object|HTTP::Response> as normal (but won't be a successful
response).

  $conf->handle_request($request, live_request_handler => sub {
      my ($live_request) = @_;

      # Make the live request somehow
      my $response = ...

      # Return the response
      return $response;
  });

=back

=head2 install_in_scope

This will install the user agent override configuration into the current scope.
The recommended install is L</install_in_user_agent> but if what needs to be
tested does not expose the user agent for manipulation, then that method should
be used. This will return a scalar reference
L<Test::Override::UserAgent::Scope|Test::Override::UserAgent::Scope>,
that until destroyed (by going out of scope, for instance) will override all
L<LWP::UserAgent|LWP::UserAgent> requests.

  # Current config in $config
  {
      # Install in this scope
      my $scope = $config->install_in_scope;

      # Test our API
      ok $object->works, "The object works!";
  }
  # $scope is destroyed, and so override configuration is removed

=head2 install_in_user_agent

This will install the overrides directly in a user agent, allowing for
localized overrides. This is the preferred method of overrides. This will
return the user agent that has the overrides installed.

  # Install into a user agent
  $ua_override->install_in_user_agent($ua);

  # Install into a new copy
  my $new_ua = $ua_override->install_in_user_agent($ua, clone => 1);

The first argument is the user agent object (expected to have the C<add_handler>
method) that the overrides will be installed in. After that, the method takes a
hash of arguments:

=over 4

=item clone

This is a Boolean specifying to clone the given user agent (with the C<clone>
method) and install the overrides into the new cloned user agent. The default
is C<0> to not clone the user agent.

=back

=head2 override_request

This will add a new request override to the configuration. The arguments
are a plain hash (C<%matches>) followed by a subroutine reference that will
return the response.

  $config->override_request(%matches, \&gen_response);

The following are they keys you may specify in C<%matches>:

=over

=item C<host>

This is a string of the host of the requested URI. This will cause a match
if the requested URI has this as the host.

  $request->uri->host eq $host;

=item C<method>

This is a string of the request method to match on. This will cause a match
if the request uses the specified method; the method should be in uppercase.

  $request->method eq $method;

=item C<path>

This is a string of the path of the requested URI. This will cause a match
if the requested URI has this as the path.

  $request->uri->path eq $path;

=item C<port>

This is the port number to match on. This will cause a match if the
requested URI uses the specified port number.

  $request->uri->port == $port;

=item C<scheme>

This is a string of the scheme to match on. This will cause a match if the
requested URI uses the specified scheme.

  $request->uri->scheme eq $scheme;

=item C<uri>

B<Added in version 0.004>; be sure to require this version for this feature.

This is a string of the URI to match on. This will cause a match if the
requested URI is equivilent to this.

  $request->uri->canonical eq URI->new($uri)->canonical;

=item C<url>

This is an alias for C<uri> above.

=back

=head2 uninstall_from_user_agent

This method will remove the handlers belonging to this configuration from
the specified user agent. The first argument is the user agent to remove
the handlers from.

=head1 HANDLER SUBROUTINE

The handler subroutine is what you will give to actually handle a request and
return a response. The handler subroutine is always given a
L<HTTP::Request object|HTTP::Request> as the first argument, which is the
request for the handler to handle.

The return value can be one of type kinds:

=over 4

=item L<HTTP::Response|HTTP::Response> object

=item L<PSGI|PSGI>-like response array reference

The return value is expected to be similar to C<[$code, [%headers], [@lines]]>.
The response is expected to be identical to the spec and will be validated. If
the PSGI response is invalid according to the spec, then a response with a
status code of 417 will be returned.

=back

=head1 DIAGNOSTIC HEADERS

When a request was stopped or an error was encountered within the
request-handling procedures of this module, there are some extra headers
added to the response object. These include the standard diagnostic headers
that L<LWP::UserAgent|LWP::UserAgent> will add, with one additional header.

=head2 C<Client-Date>

This is the current date and time the response was generated by the client.

=head2 C<Client-Warning>

Just like with L<LWP::UserAgent|LWP::UserAgent> this will be C<"Internal response">.

=head2 C<Client-Response-Source>

This header is unique to this module, and will indicate the source module
that generated the response. Typically this will always be C<"Test::Override::UserAgent">.
This provides additional information to determine that the response was generated
by this module instead of by the L<LWP::UserAgent|LWP::UserAgent> family of modules.

=head1 DEPENDENCIES

=over 4

=item * L<Carp|Carp>

=item * L<HTTP::Config|HTTP::Config> 5.815

=item * L<HTTP::Headers|HTTP::Headers>

=item * L<HTTP::Response|HTTP::Response>

=item * L<LWP::UserAgent|LWP::UserAgent>

=item * L<Scalar::Util|Scalar::Util>

=item * L<Sub::Install|Sub::Install> 0.90

=item * L<Try::Tiny|Try::Tiny>

=item * L<URI|URI>

=item * L<namespace::clean|namespace::clean> 0.04

=back

=head1 AUTHOR

Douglas Christopher Wilson, C<< <doug at somethingdoug.com> >>

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to
C<bug-test-override-useragent at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Override-UserAgent>. I
will be notified, and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

  perldoc Test::Override::UserAgent

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Test-Override-UserAgent>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Test-Override-UserAgent>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Test-Override-UserAgent>

=item * Search CPAN

L<http://search.cpan.org/dist/Test-Override-UserAgent/>

=back


=head1 LICENSE AND COPYRIGHT

Copyright 2010 Douglas Christopher Wilson.

This program is free software; you can redistribute it and/or
modify it under the terms of either:

=over 4

=item * the GNU General Public License as published by the Free
Software Foundation; either version 1, or (at your option) any
later version, or

=item * the Artistic License version 2.0.

=back
