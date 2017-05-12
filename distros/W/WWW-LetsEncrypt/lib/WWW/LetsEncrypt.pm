use strict;
use warnings;
use version;

package WWW::LetsEncrypt;
# ABSTRACT: A communication layer for talking to Let's Encrypt
$WWW::LetsEncrypt::VERSION = '0.002';

=pod

=head1 NAME

WWW::LetsEncrypt

=head1 SYNOPSIS

	use WWW::LetsEncrypt::JWK::RSA;
	use WWW::LetsEncrypt::Message::Registration;
	...;

	my $JWK = WWW::LetsEncrypt::JWK::RSA->new({
		...
	});

	my $Message = WWW::LetsEncrypt::Message::Registration->new({
		jwk   => $JWK,
		nonce => 'NONCE VALUE',
	});

	$Message->do_request();
	...;

=head1 DESCRIPTION

This is an unofficial implementation of the ACME protocol that can be used to
engage the Let's Encrypt servers.  We currently support RSA account keys, and
most operations in the API calls. All calls are made via LWP (or something
close enough to it).  This is just the communication layer between a server and
the Let's Encrypt's CA.  You will need to implement actually putting the
challenge information where it needs to go.

Currently, only the computation of the HTTP-01 challenge is supported, but we
should be adding dns-01 support soon.

This code is not endorsed in any way by Let's Encrypt, the ISGR, or any company
that is affiliated with Let's Encrypt.

Please use github for any bugs or requests.

=head1 AUTHOR

Michael Ballard

=head1 COPYRIGHT

Copyright (C) 2015, 2016
DreamHost

=head1 LICENSE

These modules are free software; and can be redistributed/modified under the terms of the GPLv3.

=over

=back

=cut

1;
