use strict;
use warnings;

use Test2::Bundle::Extended;
use Test2::Tools::Subtest qw/subtest_buffered/;

use HTTP::Response;
use HTTP::Headers;
use JSON;
use WWW::LetsEncrypt::JWK::RSA;
use WWW::LetsEncrypt::Message::Authorization;

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

my $JWK = WWW::LetsEncrypt::JWK::RSA::load_cert({
	private_key => $rsa_private_key,
	key_id      => 1,
	alg         => 'RS256',
});

my $Message;


sub _reset_data {
	$Message = WWW::LetsEncrypt::Message::Authorization->new({
		JWK    => $JWK,
		domain => 'example.tld',
	});
	$Message->_step('submit_challenge');
	$Message->_prep_step;
	return;
}

subtest_buffered accepted_202 => sub {
	_reset_data;
	my $mock_uri = 'https://acme-staging.example.com';
	my $Response = _MockResponse(202, {uri => $mock_uri});

	my $processed_ref = $Message->_submit_challenge_step($Response);
	like(
		$processed_ref,
		{
			successful => 1,
			finished   => 0,
		},
		'Returned successful data.'
	);
	is($Message->_step, 'polling', 'Properly set the next _step');
	is($Message->_url, $mock_uri, 'Properly populated the uri for polling.');
};

subtest_buffered error => sub {
	_reset_data;
	my $Response = _MockResponse(100);
	my $response_ref = $Message->_process_response($Response);
	is($response_ref, {error =>1}, 'Properly caught the error');
};

done_testing;

sub _MockResponse {
	my ($code, $hash_ref) = @_;
	$hash_ref ||= {};
	return HTTP::Response->new(
		$code,
		'',
		HTTP::Headers->new(),
		encode_json($hash_ref)
	);
}
