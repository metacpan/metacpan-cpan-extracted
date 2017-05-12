package WWW::LetsEncrypt::Message::Registration;
$WWW::LetsEncrypt::Message::Registration::VERSION = '0.002';
use strict;
use warnings;

use JSON;
use HTTP::Request;
use HTTP::Status qw(RC_CREATED RC_ACCEPTED RC_FORBIDDEN RC_CONFLICT);
use Moose;

extends 'WWW::LetsEncrypt::Message';

=pod

=head1 NAME

WWW::LetsEncrypt::Message::Registration - ACME registration message

=head1 SYNOPSIS

	use WWW::LetsEncrypt::Message::Registration;
	my $JWK = ...;

	# Step 1 Register
	my $RegMsg = WWW::LetsEncrypt::Message::Registration->new({
		JWK     => $JWK,
		contact => ['mailto:noreply@example.tld', ...],
		nonce   => 'NONCE_VALUE',
	});

	my $result = $RegMsg->do_request();

	#handle $result ...

	# Step 2 Agreement

	$RegMsg->agreement('URL_TO_CURRENT_AGREEMENT');
	$result = $RegMsg->do_request();

	#handle result...

=head1 DESCRIPTION

This class implements the two-step process for registering a Let's Encrypt
account.

=head2 Attributes

=over 4

=item contact

	an array reference that contains a list of valid contact information
	strings.

=item agreement

	a scalar string that holds the URI to the agreement, a truthy value
	here denotes acceptance of said agreement!

=item id

	a scalar integer that represents the ACME account ID, necessary when
	updating any account detail. This value will be automatically set after a
	registration occurs.

=back

=cut

has 'contact' => (
	is       => 'rw',
	isa      => 'ArrayRef[Str]',
	required => 1,
);

has 'agreement' => (
	is => 'rw',
	isa => 'Str',
);

has 'id' => (
	is  => 'rw',
	isa => 'Int',
);

=head2 Public Functions

=over 4

=item $Obj->update_only()

Object function that marks the Registration message as being only used for
updates to the ACME account.

Output

	nothing

=cut

sub update_only {
	my ($self) = @_;
	$self->_prep_update_step;
	return;
}

=back

=cut

sub _process_response {
	my ($self, $Response) = @_;
	confess 'Response was not passed!' if !$Response;

	# System's reponse to new-reg or reg is the same, 201 CREATED,
	# and we will follow the same processing path for both (mostly).

	my $status_code  = $Response->code();
	if ($status_code == RC_CREATED) {
		$self->_step('update') if $self->_step() eq 'new-reg';
		my $server_response = decode_json($Response->content);
		my $resp_ref = {%$server_response};
		$resp_ref->{successful} = 1;

		return $resp_ref;
	} elsif ($status_code == RC_ACCEPTED) {
		return {
			successful => 1,
			finished   => 1,
		};
	} elsif ($status_code == RC_FORBIDDEN) {
		my $err_ref = decode_json($Response->content);
		if ($err_ref->{type} =~ m/unauthorized$/
			&& $err_ref->{detail} =~ m/^No registration/) {
			return {
				successful => 0,
				finished   => 1,
				not_reg    => 1,
			};
		} else {
			return {error => 1};
		}
	} elsif ($status_code == RC_CONFLICT) {
		# We appear to have tried to re-register this account_key pair, woops.
		my $server_response = decode_json($Response->content);
		my $resp_ref = {%$server_response};
		$resp_ref->{successful}         = 0;
		$resp_ref->{already_registered} = 1,
		return $resp_ref;
	} else {
		return {error => 1};
	}
}

sub _prep_step {
	my ($self) = @_;
	my $step = $self->_step;
	if ($step) {
		my $step_function = "_prep_${step}_step";
		return $self->$step_function;
	}
	# By default, we assume that if a step is not specified, that we are updating.
	return $self->_prep_new_reg_step();
}

# $Obj->_prep_new_reg_step()
#
#Internal object function that prepares the Registration message for new
#registration.
#
#Output
#	$scalar boolean if preparing was successful.

sub _prep_new_reg_step {
	my ($self) = @_;
	$self->_step('new-reg');

	# Setup the HTTP Request
	my $uri = $self->acme_base_url() . '/acme/new-reg';
	my $Request = HTTP::Request->new(POST => $uri);
	$self->_Request($Request);

	# Setup payload
	my $payload = $self->_standard_payload();
	$payload->{resource} = 'new-reg';

	$self->_payload($payload);

	return 1;
}

# $Obj->_prep_update_step()
#
#Internal object function that prepares the Registration message for updating
#an ACME account.
#
#Output
#	$scalar boolean if preparing was successful.

sub _prep_update_step {
	my ($self) = @_;
	confess 'id field required if updating registration' if !$self->id;
	$self->_step('update');

	# Setup the HTTP Request
	my $id = $self->id;
	my $uri = $self->acme_base_url() . "/acme/reg/$id";
	my $Request = HTTP::Request->new(POST => $uri);
	$self->_Request($Request);

	# Setup payload
	my $payload = $self->_standard_payload();
	$payload->{resource} = 'reg';
	$payload->{agreement} = $self->agreement if $self->agreement;
	$self->_payload($payload);

	return 1;
}

sub _standard_payload {
	my ($self) = @_;
	return {
		contact   => $self->contact,
		key       => $self->JWK->serialize_public_key(),
	};
}

__PACKAGE__->meta->make_immutable;
