package WWW::LetsEncrypt::Message::Authorization;
$WWW::LetsEncrypt::Message::Authorization::VERSION = '0.002';
use strict;
use warnings;

use Carp qw(confess);

use Digest::SHA;
use HTTP::Request;
use HTTP::Status qw(RC_CREATED RC_FORBIDDEN);
use JSON;
use MIME::Base64 qw(encode_base64url);
use Moose;
use Moose::Util::TypeConstraints;

extends qw(WWW::LetsEncrypt::Message);

=pod

=head1 NAME

WWW::LetsEncrypt::Message::Authorization

=head1 SYNOPSIS

	use WWW::LetsEncrypt::Message::Authorization;

	my $JWK = ...;
	my $AuthMsg = WWW::LetsEncrypt::Message::Authorization->new({
		challenge => 'http-01',     # Optional,
		domain    => 'example.tld', # Required,
	});

	# Step 1: Request Auth Token
	my $result = $AuthMsg->do_request();
	die 'failed' if !$result->{successful};
	my $challenge_token_name = $result->{token};
	my $challenge_token_data = $result->{content};

	# Do a thing to make token/content consumable by Let's Encrypt
	# (eg: populate .well-known/acme/$challenge_token_name with $challenge_token_data

	# Step 2: Submit Auth Challenge
	$result = $AuthMsg->do_request()
	die 'failed' if !$result->{successful};

	# Step 3...: Polling
	$result = $AuthMsg->do_request();
	...
	#sleep maybe?
	goto 3 or not


=head1 DESCRIPTION

	This class provides an method for authorizing a domain, currently by http-01.

=head2 Attributes

(Includes all attributes inherited from WWW::LetsEncrypt::Message)

=over 4

=item challenge

	an attribute that holds a string of the challenge method.
	Current implemented methods include:

=over 4

=item http-01 (the renamed simpleHttp)

=item dns-01

=back

=item domain

	a string attribute that holds the domain you are trying to authorize.

=back

=cut

has 'challenge' => (
	is       => 'rw',
	isa      => enum(['http-01', 'dns-01']),
	required => 1,
	default  => 'http-01',
);

has 'domain' => (
	is  => 'ro',
	isa => 'Str',
	required => 1,
);

# '_key_auth_token' a private string attribute that holds the challenge value.
has '_key_auth_token' => (
	is  => 'rw',
	isa => 'Str',
);

# '_token' a private string attribute that holds the name of the challenge value.
has '_token' => (
	is  => 'rw',
	isa => 'Str',
);

sub _process_response {
	my ($self, $Response) = @_;
	my $process_step = "_" . $self->_step . "_step";
	return $self->$process_step($Response);
}

# $Obj->_create_key_auth_token()
#
#Internal object function that generates the challenge response data.
#
#Output
#	An array where the first value should be used for provisioning proof,
#	and the second value should be submitted back via JWT to Boulder.

sub _create_key_auth_token {
	my ($self)     = @_;
	my $token      = $self->_token;
	my $challenge  = $self->challenge;
	my $thumbprint = $self->JWK->thumbprint();
	my $auth_value = "$token.$thumbprint";

	# Boulder's API looks for the "$token.$thumb" value when we confirm
	# that it should go look for the proof.  However, the proof value
	# differs between the various challenges so we need to calculate that.
	my $proof_value;
	if ($challenge eq 'dns-01') {
		$proof_value = encode_base64url(Digest::SHA::sha256($auth_value));
	} else {
		# such is the case with http-01.
		$proof_value = $auth_value;
	}

	return ($proof_value, $auth_value);
}

sub _prep_request_step {
	my ($self) = @_;

	# Setup HTTP Request
	my $uri = $self->acme_base_url() . '/acme/new-authz';
	my $Request = HTTP::Request->new(POST => $uri);
	$self->_Request($Request);

	# Generate payload
	my $payload = {
		resource => 'new-authz',
		identifier => {
			type  => 'dns',
			value => $self->domain,
		},
	};
	$self->_payload($payload);

	return 1;
}

# $Obj->_request_step($Response)
#
#Step 1 of the process, returns necessary data that should be pushed to a machine which will be used for authorization.
#
#Input
#	$Response - HTTP::Response object referece
#
#Output
#	\%hash_ref = {
#		successful => bool if actions was successful,
#		finished   => bool if all steps are completed,
#		token      => name of the challenge response resource
#		content    => data to be returned for the challenge response
#		no_tos     => bool if the Terms of Service have not been agreed to (error)
#	}

sub _request_step {
	my ($self, $Response) = @_;
	my $output_ref;
	if ($Response->code == RC_CREATED) {
		my $response_ref = decode_json($Response->content);

		if ($response_ref->{status} eq 'pending') {
			my ($challenge_ref) = grep { $_->{type} eq $self->challenge } @{$response_ref->{challenges}};
			confess "Challenge '" . $self->challenge ."' could not be selected!"
				if (!$challenge_ref);

			$self->_url($challenge_ref->{uri});
			$self->_token($challenge_ref->{token});

			my ($proof_val, $submit_val) = $self->_create_key_auth_token();
			$self->_key_auth_token($submit_val);

			$output_ref = {
				token      => $self->_token,
				content    => $proof_val,
				successful => 1,
				finished   => 0,
			};
			$self->_step('submit_challenge');
		} else {
			return {error => 1};
		}
	} elsif ($Response->code == RC_FORBIDDEN) {
		my $response_ref = decode_json($Response->content);
		if ($response_ref->{type} eq 'urn:acme:error:unauthorized') {
			if ($response_ref->{detail} =~ m/^Must agree to/) {
				return {
					finished   => 1,
					successful => 0,
					no_tos     => 1,
				};
			} else {
				return {error => 1};
			}
		}
	} else {
		return {error => 1};
	}
	return $output_ref;
}

sub _prep_submit_challenge_step {
	my ($self) = @_;

	# Setup HTTP Request
	my $uri = $self->_url;
	my $Request = HTTP::Request->new(POST => $uri);
	$self->_Request($Request);

	$self->_payload({
		resource         => 'challenge',
		KeyAuthorization => $self->_key_auth_token,
	});

	return 1;
}

# $Obj->_submit_challenge_step($Response)
#
#Step 2 in the process of authorization. Note is is possible for early
#finishing if the server is able to check after processing the request but
#before returning a response.
#
#Input
#	$Response - HTTP::Response object reference
#
#Output
#	\%hash_ref = {
#		sucessful => bool if step was successful
#		finished  => false
#	}

sub _submit_challenge_step {
	my ($self, $Response) = @_;

	my $response_ref = decode_json($Response->content());
	if ($Response->code == 202) {
		$self->_step('polling');
		$self->_url($response_ref->{uri});
		$response_ref->{successful} = 1;
		$response_ref->{finished} = 0;
		return $response_ref;
	} elsif ($Response->code == 200) {
		return {
			successful => 1,
			finished   => 1,
		}
	} else {
		return {error => 1};
	}
}

sub _prep_polling_step {
	my ($self) = @_;

	my $Request = HTTP::Request->new(GET => $self->_url);
	$self->_Request($Request);

	return 1;
}

# $Obj->_polling_step($Response)
#
#Last step, polling to see if the authorization was successful
#Input
#	$Response - HTTP::Response object ref
#Output
#	\%hash_ref = {
#		successful => bool if authorization has been accepted
#		finished   => bool if all steps have been completed (re-polling will set this false)
#		retry      => bool if polling should be retried (also check retry_time attribute)
#		fault      => \%hashref that contains information about the fault that occurred
#	}

sub _polling_step {
	my ($self, $Response) = @_;
	if ($Response->code == 202) {
		my $response_ref = decode_json($Response->content());
		my $status_func = $self->can("_polling_" . $response_ref->{status});
		return $status_func->($self, $response_ref, $Response);
	}
	return {error => 1};
}

sub _polling_pending {
	my ($self, $response_ref, $Response) = @_;

	# If the retry_after header isn't present, wait 1 second.
	my $retry_time = $Response->header('retry_after') || 1;
	$self->retry_time($retry_time);
	return {
		successful => 1,
		finished   => 0,
		retry      => 1,
	};
}

sub _polling_valid {
	my ($self, $response_ref) = @_;
	my $expires = $response_ref->{expires};
	return {
		successful => 1,
		finished   => 1,
		uri        => $response_ref->{uri},
		expires    => $expires,
	}
}

sub _polling_invalid {
	my ($self, $response_ref) = @_;
	return {
		successful => 0,
		finished   => 1,
		fault      => $response_ref->{error},
	};
}

sub _prep_step {
	my ($self) = @_;
	my $step = $self->_step;
	my $step_function;
	if ($step) {
		$step_function = "_prep_${step}_step";
	} else {
		$step_function = "_prep_request_step";
		$self->_step('request');
	}
	return $self->$step_function;
}

__PACKAGE__->meta->make_immutable;

