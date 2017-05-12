package WWW::LetsEncrypt::Message::Certificate;
$WWW::LetsEncrypt::Message::Certificate::VERSION = '0.002';
use HTTP::Status qw(RC_OK RC_CREATED RC_ACCEPTED RC_FORBIDDEN);
use JSON;
use Moose;

extends 'WWW::LetsEncrypt::Message';

=pod

=head1 NAME

WWW::LetsEncrypt::Message::Certificate - ACME messages

=head1 SYNOPSIS

	use WWW::LetsEncrypt::JWK;
	use WWW::LetsEncrypt::Message::Certificate;

	my $JWK = ...;
	my $DER_encoded_ssl_cert_string = ...;

	my $CertMsg = WWW::LetsEncrypt::Message::Certificate->new({
		cert  => $DER_encoded_csr_string,
		JWK   => $JWK,
		nonce => 'nonce_string',
	});

	my $result_ref = $CertMsg->do_request();
	if ($result_ref->{successful}) {
		if ($result_ref->{finished}) {
			my $DER_encoded_cert_string = $result_ref->{cert};
			# do a thing with ^
		} else {
			sleep $CertMsg->retry_time;
			# while !sucessful
			$result_ref = $CertMsg->do_request();
			# then do a thing with $result_ref->{cert}
			# it contains the DER encoded signed certificate
		}
	}

	---------------------------

	my $CertMsg = WWW::LetsEncrypt::Message::Certificate->new({
		cert   => $DER_encoded_cert_string,
		JWK    => $JWK,
		nonce  => 'nonce_string',
		revoke => 1,
	});

	my $result_ref = $CertMsg->do_request();
	# Check successful if it will be revoked.

=head1 DESCRIPTION

This module implements certificate requests and revocation messages for the ACME protocol.

=head2 Attributes

=over 4

=item cert

a scalar string that is the DER encoded CSR for certificate
requests OR DER encoded CERT for certificate revocation. Note: This MUST be a
DER encoded string.  PEM is not going to cut it. This attribute is required.

=item revoke

a scalar boolean that causes the message to perform revocation.

=back

=cut

has 'cert' => (
	is       => 'rw',
	isa      => 'Str',
	required => 1,
);

has 'revoke' => (
	is  => 'rw',
	isa => 'Bool',
);


sub _process_response {
	my ($self, $Response) = @_;
	my $step_function = "_" . $self->_step() . "_step";
	return $self->$step_function($Response);
}

sub _prep_step {
	my ($self) = @_;
	if ($self->_step) {
		my $step = "_prep_" . $self->_step . "_step";
		return $self->$step();
	} elsif ($self->revoke) {
		my $step = "_prep_revocation_step";
		$self->_step('revocation');
		return $self->$step;
	}
	$self->_step('submit');
	return $self->_prep_submit_step();
}

sub _prep_revocation_step {
	my ($self) = @_;

	confess 'A Certificate must be provided for revocation!'
		if !$self->cert;

	my $uri = $self->acme_base_url() . "/acme/revoke-cert";
	$self->_Request(HTTP::Request->new(POST => $uri));

	$self->_payload({
		resource    => 'revoke-cert',
		certificate => $self->cert,
	});
	return 1;
}

# $Obj->_revocation_step($Response)
#
#Internal function that processes revocation messages.
#
#Input
#	$Response - HTTP::Response object reference
#
#Output
#	# if revocation was successful
#	\%hash_ref = {
#		successful => 1,
#		finished   => 1,
#	}
#
#	# if it has been revoked already
#	\%hash_ref = {
#		successful => 0,
#		finished   => 1,
#	}
#
#	# Else, an error \%hashref

sub _revocation_step {
	my ($self, $Response) = @_;
	if ($Response->code() == RC_OK) {
		return {
			successful => 1,
			finished   => 1,
		};
	} elsif ($Response->code() == RC_FORBIDDEN) {
		return {
			successful      => 0,
			finished        => 1,
			already_revoked => 1,
		};
	}
	return {error => 1}
}

sub _prep_submit_step {
	my ($self) = @_;

	my $uri = $self->acme_base_url() . "/acme/new-cert";
	$self->_Request(HTTP::Request->new(POST => $uri));

	confess 'CSR must be provided for certificate submission!'
		if !$self->cert;

	$self->_payload({
		resource => 'new-cert',
		csr      => $self->cert,
	});
	return 1;
}

# $Obj->_submit_step($Response)
#
#Internal function that handles CSR submission
#
#Input
#	$Response - HTTP::Response object reference
#
#Output
#	# If the certificate is signed upon request
#	\%hash_ref = {
#		sucessful => 1,
#		finished  => 1,
#		cert      => scalar string that is the DER encoded certificate,
#	}
#
#	# If polling will be necessary
#	\$hash_ref = {
#		sucessful => 1,
#		finished  => 0,
#	}

sub _submit_step {
	my ($self, $Response) = @_;
	if ($Response->code() == RC_ACCEPTED) {
		my $polling_url = $Response->header('location');
		$self->_step('poll');
		return {
			successful => 1,
			finished   => 0,
		};
	} elsif ($Response->code() == RC_CREATED) {
		return {
			successful => 1,
			finished   => 1,
			cert       => $Response->content(),
		}
	}
	return {error => 1};
}

sub _prep_poll_step {
	my ($self) = @_;
	$self->_payload({});
	my $Request = HTTP::Request->new(GET => $self->_url);
	$Request->header('Accept-Encoding' => 'application/x-pem-file');
	$self->_Request($Request);
	return 1;
}

# $Obj->_poll_step($Response)
#
#Internal function that polls the ACME server for the certificate
#
#Input
#	$Response - HTTP::Response object reference
#
#Output
#	# If the certificate is signed upon request
#	\%hash_ref = {
#		sucessful => 1,
#		finished  => 1,
#		cert      => scalar string that is the DER encoded certificate,
#	}
#
#	# If polling will be necessary
#	\$hash_ref = {
#		sucessful => 1,
#		finished  => 0,
#	}

sub _poll_step {
	my ($self, $Response) = @_;
	if ($Response->code() == RC_ACCEPTED) {
		my $wait_time = $Response->header('Retry-After');
		$self->retry_time($wait_time);
		return {
			successful => 1,
			finished   => 0,
		};
	} elsif ($Response->code() == RC_OK) {
		my $cert = $Response->content();
		return {
			successful => 1,
			finished   => 1,
			cert       => $cert,
		};
	} else {
		return {error => 1};
	}
}

=back

=cut

__PACKAGE__->meta->make_immutable;
