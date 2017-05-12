use strict;
use warnings;

use Test2::Bundle::Extended;
use Test2::Mock;
use Test2::Tools::Subtest qw/subtest_buffered/;

use HTTP::Headers;
use HTTP::Response;
use HTTP::Request;
use WWW::LetsEncrypt::Message;
use WWW::LetsEncrypt::JWK::RSA;

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

my ($Message, $retry_value);

sub _reset_data {
	$Message = WWW::LetsEncrypt::Message->new({
		JWK => $JWK,
	});
	$Message->_Request(HTTP::Request->new(POST => 'http://example.com'));
	$Message->_payload({isa => 'thing'});
}
my $takeover_LE_message = Test2::Mock->new(
	class    => 'WWW::LetsEncrypt::Message',
	override => [
		_need_nonce => sub { return 0; },
		_prep_step  => sub { return undef; },
	]
);

my $takeover_LWP = Test2::Mock->new(
	class    => 'LWP::UserAgent',
	override => [
		request => sub {
			return HTTP::Response->new(
				429,
				'',
				HTTP::Headers->new(
					Retry_After => $retry_value,
					Replay_Nonce => 'SOMETHING'
				),
			);
		}
	]
);

subtest_buffered do_request_429 => sub {
	_reset_data();
	my $response_ref = $Message->do_request();
	my $expected_ref = {
		rc           => 429,
		rate_limited => 1,
		finished     => 1,
		successful   => 0,
	};
	like($response_ref, $expected_ref, 'rate_limited value is truthy.');
};

done_testing;

