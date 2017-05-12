package WWW::LetsEncrypt::Message::Directory;
$WWW::LetsEncrypt::Message::Directory::VERSION = '0.002';
use JSON;
use Moose;

extends 'WWW::LetsEncrypt::Message';

=pod

=head1 NAME

WWW::LetsEncrypt::Message::Directory

=head1 SYNOPSIS

	use WWW::LetsEncrypt::Message::Directory;

	my $Directory = WWW::LetsEncrypt::Message::Directory->new();

	my $result_ref = $Directory->do_request();
	my $urls_ref   = $result_ref->{directory};

	# Save the nonce for later, maybe?
	my $nonce = $Directory->nonce();

=head1 DESCRIPTION

This module implements the ACME message for requesting the directory from the
server. Note: This does not perform any kind of configuration for later
messages.  Mostly used to get the first nonce for later ACME messages.

=cut

# JWK is not required for this operation.
has '+JWK' => (required => 0);

=head2 Private Functions

=over 4

=cut

sub _prep_step {
	my ($self) = @_;
	my $uri = $self->acme_base_url() . "/directory";
	$self->_Request(HTTP::Request->new(GET => $uri));
	return 1;
}

=item _process_response

Internal function that processes revocation messages.

Input

	$self     - Object reference
	$Response - HTTP::Response object reference

Output

	# if getting the directory was successful
	\%hash_ref = {
		successful => 1,
		finished   => 1,
		directory  => \%hash_ref that is the directory information (see the RFC)
	}

	# Otherwise
	\%hash_ref = {
		successful => 0,
		finished   => 1,
	}

	# Else, an error \%hashref

=cut

sub _process_response {
	my ($self, $Response) = @_;
	if ($Response->code() == 200) {
		my $json_data = decode_json($Response->content());
		return {
			successful => 1,
			finished   => 1,
			directory  => $json_data,
		};
	}
	return {
		successful => 0,
		finished   => 1,
	};
}

# Nonces are not needed for Directory Messages
sub _need_nonce {
	return 0;
}

# JWKs are not needed for a Directory GET.
sub _need_jwk {
	return 0;
}

__PACKAGE__->meta->make_immutable;
