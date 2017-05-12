use strict;
use warnings;

use Test2::Bundle::Extended;
use Test2::Tools::Subtest qw/subtest_buffered/;

use JSON;
use MIME::Base64 qw(decode_base64url);
use WWW::LetsEncrypt::JWK::RSA;
use WWW::LetsEncrypt::JWS;

my $rsa_private_key =<<'END';
-----BEGIN RSA PRIVATE KEY-----
MIICXQIBAAKBgQDq3D0BY8g9gQ/C1kByAcXgZBGo3Ww/RnFNkEA8hdtq8UVIpK6I
eUgpTIdI83OH7OTz7yNU6FXuchIKfsoKZNKq7LQsYaK4OxJqDrpsoTy5dq9cXFCP
11sxXJCy5uMtyXy+trFbBEjsbhqgOTYiTVy6yPqAc7pEGd6ZA2j3ECruhQIDAQAB
AoGAZK2wwS3DIwp2dTFfQwAbkUuUfm0dACr0WymhP9Cp9Lgk2TUvVHWZR4r024Lx
Xa1hoGg9HyLR43um3DTp63a5D5YuiVTJPJ5ldwzg9bXg7TyZF31hCWNjW/aIHdbk
IojfGkxRNSLJnxUqqUL4u+sD/TvMDoD5n2m/xWNE+0/fhykCQQD/Vue4EBQexj+z
KyytAqZbOffEFDbg12+AT0pHLE2hNeAu9TQXktYLVqcG2mMhxp9iR5mf9P+CGU0g
8q6rYCAnAkEA63fFaBrpS1DorF33HwMiv4ycNi7WDWEw9UbtZg1bM0BVj1bPdxVP
0oVLnIQty6KSAiRwERhQR88SmG49j4C7cwJBAIuSBmE/MLBNr14RWH9Ndn9hJUSh
xAmM2R7quHBFED3xhBRG5e2IzsUt3WjKkOtSdaaz+o5LzipgCB/dZ4q3pXsCQQDM
8jh9/j5kcY2yyS6YbZBHDMnCV02z445LTmq+0o04tJxD4Jk+2uvZHm/LUTjS7zMK
blCkcHcfqVpUFk+6oZ+FAkA6ytcHSHmzRDsMe5aQuD2SJhZ/XtA5vXYFKf5SXGni
Jwd0k2SrxvrrIE9ieWlbHzV1Acw1AL1jSZ6sVZcXEkZi
-----END RSA PRIVATE KEY-----
END

subtest_buffered serializing => sub {
	my $payload = {
		a => 'b',
		b => 'c',
		c => 'd',
	};

	my $JWK = WWW::LetsEncrypt::JWK::RSA::load_cert({
		private_key => $rsa_private_key,
		key_id      => 1,
		alg         => 'RS256',
	});

	my $JWS = WWW::LetsEncrypt::JWS->new({
		payload => $payload,
		jwk     => $JWK,
	});

	my $jws_ref = decode_json($JWS->serialize());

	is(_decode($jws_ref->{payload}), $payload, 'generated a proper payload');
	my $decoded_protected_header = _decode($jws_ref->{protected});
	like($decoded_protected_header, {alg => 'RS256'},'Created a proper protected header');
	is(
		$decoded_protected_header->{jwk},
		$JWK->serialize_public_key,
		'Protected header has the correct public key'
	);
	is($jws_ref->{header}, undef, 'Header should not be present.');


	my $header = {item1 => '1'};
	$JWS = WWW::LetsEncrypt::JWS->new({
		payload => $payload,
		headers => $header,
		jwk     => $JWK,
	});

	$jws_ref = decode_json($JWS->serialize());
	is($jws_ref->{header}, $header, 'Created a proper header.');
	is(_decode($jws_ref->{payload}), $payload, 'Created a proper payload.');
	like(_decode($jws_ref->{protected}), {alg => 'RS256'}, 'created a proper protected header');
};

done_testing;

sub _decode {
	my ($val) = @_;
	return decode_json(decode_base64url($val));
}
