package WWW::LetsEncrypt::Message;
$WWW::LetsEncrypt::Message::VERSION = '0.002';
use strict;
use warnings;

use constant {RC_TOO_MANY_REQUESTS => 429};

use Carp qw(confess);

use JSON;
use LWP::UserAgent;
use Moose;
use Moose::Util::TypeConstraints;
use WWW::LetsEncrypt::JWS;
use Try::Tiny;

=head1 NAME

WWW::LetsEncrypt::Message - Base class for all ACME messages.

=head1 SYNPOSIS

	package Some::Acme::Message;

	use Moose;
	extends 'WWW::LetsEncrypt::Message';

	# implement functions required functions
	...

=head1 DESCRIPTION

This is an abstract class that provides the basis for ACME messages being sent
to the Let's Encrypt CA server.

=head2 Attributes

=over 4

=item _acme_base_url

private attribute that holds the ACME API URL. Defaults to the
Let's Encrypt API URL, cannot be changed once the object has been created.

=item JWK

JSON Web Key object that implements both JWK and JWA (will be passed to
a JWS object). This is required.

=item nonce

scalar attribute that holds the nonce. It will be used when sending
messages, and will be automatically refreshed upon receiving a message from
the Let's Encrypt CA server. This attribute is not required but messages w/o
a valid nonce may fail!

=item retry_time

scalar integer attribute that holds how much time the client
should wait before trying to send another API request. This value being true
usually means an HTTP 429 was encountered and that the client should back off.

=item WebAgent

object attribute that holds an instance of LWP::UserAgent (or
anything that happens to implement the same functions). If not provided during
initialization, a new LWP::UserAgent object will be created with the following
settings:

=over 4

=item protocols allows: https

=item agent: LE-Bot (libwww-perl)

=item ssl_option: verify_hostname => true

=back

=back

=cut

has 'acme_base_url' => (
	is       => 'ro',
	isa      => 'Str',
	default  => 'https://acme-v01.api.letsencrypt.org',
);

has 'JWK' => (
	is       => 'ro',
	isa      => 'Object',
	required => 1
);

has 'nonce' => (
	is      => 'rw',
	isa     => 'Str',
);

has 'retry_time' => (
	isa      => 'Int',
	is       => 'rw',
	init_arg => undef,
);

has 'WebAgent' => (
	is       => 'rw',
	isa      => duck_type("LWUA_Compatible" => [qw(request)]),
	required => 1,
	default  => sub {
		return LWP::UserAgent->new(
			ssl_opts          => { verify_hostname => 1 },
			protocols_allowed => ['https'],
			agent             => 'LE-Bot (libwww-perl)',
		);
	},
);

# '_payload' private attribute that holds the payload hashref, which will be put
# into the JWS and sent to the server.

has '_payload' => (
	is       => 'rw',
	isa      => 'HashRef',
	default  => sub { return {} },
	init_arg => undef,
);

# '_Request' private attribute that holds an HTTP::Request object. Derived
# classes must set this prior to do_request() being called, as this object will
# be passed to WebAgent to consume.

has '_Request' => (
	is       => 'rw',
	isa      => 'Object',
	init_arg => undef,
);

# '_step' private attribute that should be used to keep track of the what step
# the Message object is currently performing.

has '_step' => (
	is  => 'rw',
	isa => 'Str',
);

# '_uri' private attribute that potentially holds the URL for the next step,
# which is necessary for some messages that contain a URL that is dynamically
# generated and must be followed.

has '_url' => (
	is  => 'rw',
	isa => 'Str',
);

=head2 Functions

=over 4

=item $Obj->do_request()

This method is the primary method that a client should use to perform message
calls out to an ACME server.  It performs some error handling, but passes all
major processing off to a derived class's _process_request function.

Output

	\%hash_ref = {
		successful => boolean value that expresses if a step performed successfully,
		finished   => boolean value that expresses if all steps have been performed,
		error      => boolean value that expresses a FATAL error has occurred,
		...
		(other values depending on step)
	}

=cut

sub do_request {
	my ($self) = @_;
	$self->_prep_step();
	my %payload = %{$self->_payload};
	confess 'nonce was not set, but is required.'
		if $self->_need_nonce && !$self->nonce;

	my $Request = $self->_Request;

	my $JWS;

	# Technically speaking the RFC for JWA allows for a 'none' algorithm.
	# But Let's Encrypt doesn't make use of it, and so we aren't going to
	# try to support that.
	if ($self->_need_jwk) {
		$JWS = WWW::LetsEncrypt::JWS->new({
			jwk               => $self->JWK(),
			payload           => \%payload,
			protected_headers => {
				nonce => $self->nonce,
			},
		});
		$Request->content($JWS->serialize()) if $Request->method eq 'POST';
	}

	my $Response;
	# Attempt to retry the connection at most 3 times if a client-warning
	# is being thrown.  This is typically due to either: resolution failure
	# or connection to the host timed out.
	for my $iteration (1..3) {
		$Response = $self->WebAgent->request($Request);
		last if !$Response->header('client-warning');
	}

	# Grab and store the nonce from the message.
	my $got_nonce = $self->_get_nonce($Response);
	confess 'Unable to get a new nonce.  This is problematic.' if !$got_nonce;

	# Reset the retry_time after each request
	$self->retry_time(0);

	my $rate_limited = 0;

	if (my $retry_after = $Response->header('Retry-After')) {
		$self->retry_time($retry_after);
	}
	$rate_limited = 1 if $Response->code == RC_TOO_MANY_REQUESTS;

	# TODO: Error processing.

	# Hand over the derived classes for content processing
	my $processed_response;
	$processed_response = $self->_process_response($Response) if !$rate_limited;

	if ($processed_response->{error} || $rate_limited) {
		my $err_ref;
		try {
			$err_ref = decode_json($Response->content());
		} catch {
			$err_ref->{message} = $Response->content();
			$err_ref->{failed_parsing} = 1;
			$err_ref->{error} = 1;
		};
		$err_ref->{rc}           = $Response->code;
		$err_ref->{errmsg}       = $Response->message;
		$err_ref->{rate_limited} = 1 if $rate_limited;
		$err_ref->{successful}   = 0;
		$err_ref->{finished}     = 1;
		return $err_ref;
	} else {
		return $processed_response;
	}
}

=back

=cut

# $Obj->_get_nonce($Response)
#
#Internal object function that grabs the nonce value from the header and tries to
#update the nonce attribute.
#
#Input
#	$Response - HTTP::Response object reference
#
#Output
#	$scalar boolean that denotes if the action was successful

sub _get_nonce {
	my ($self, $Response) = @_;
	my $header_nonce = $Response->header('replay_nonce') || '';
	# Presumably all valid responses will contain a nonce that we will use for the next message out.
	$self->nonce($header_nonce);
	return ($header_nonce and $header_nonce eq $self->nonce);
}

# $Obj->_prep_step()
#
#Internal object function that must be implemented by a derived class. This
#function is called during do_request on the Message object, and it should
#cause the derive class to prepare for handling the next (or first) step.
#
#
#Output
#	discarded.  If failure occurs, it should be fatal.

sub _prep_step {
	confess 'Not Implemented';
}

# $Obj->_process_response($Response)
#
#Internal object function that must be implemented by the derived class. This
#function should implement any processing necessary for the derived Message
#class or call other methods to handle the processing.
#
##Input
#	$Response - HTTP::Response object reference
#
#Output
#	\%hash_ref = {
#		successful => boolean value that expresses if a step performed successfully,
#		finished   => boolean value that expresses if all steps have been performed,
#		error      => boolean value that expresses a FATAL error has occurred,
#		...
#		(other values depending on step)
#	}

sub _process_response {
	confess 'Not Implemented.';
}

# $Obj->_need_nonce()
#
#Internal function that should be used to specify if the do_request call will
#require a nonce. Implementing classes should override this function if they do
#not require a nonce.  Currently, presenting a nonce when none is needed does
#not cause an error.
#
#Output
#	$scalar boolean if a nonce is required (defaults to true)

sub _need_nonce {
	# By default, most messages require a nonce.
	return 1;
}

# $Obj->_need_jwk
#
# Internal object method used for checking if the JWK will be needed.
# Almost all messages need access to the JWK due to signing requests, however,
# there may be exceptions to this rule that must be accounted for.
#
# Output
#	$scalar boolean if a JWK object is requred (defaults to true)

sub _need_jwk {
	return 1;
}

__PACKAGE__->meta->make_immutable;
