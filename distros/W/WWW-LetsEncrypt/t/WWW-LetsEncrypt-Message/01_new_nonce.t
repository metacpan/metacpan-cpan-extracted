use strict;
use warnings;

use Test2::Bundle::Extended;
use Test2::Mock;
use Test2::Tools::Exception qw/dies/;
use Test2::Tools::Mock qw/mock_obj/;
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

my $Message;

sub _reset_data {
	$Message = WWW::LetsEncrypt::Message->new({
		JWK => $JWK,
	});
	$Message->_Request(HTTP::Request->new(POST => 'http://example.com'));
	$Message->_payload({isa => 'thing'});
	return;
}

subtest_buffered setting_new_nonce => sub {
	_reset_data();
	my $prev_nonce = 'NO_NONCE';
	my $next_nonce = 'NEXT_NONCE';
	$Message->nonce($prev_nonce);
	my $Response = HTTP::Response->new(
		200,
		'',
		HTTP::Headers->new(replay_nonce => $next_nonce),
	);
	ok($Message->_get_nonce($Response), '_get_nonce returned successfully');
	is($Message->nonce, $next_nonce, 'new nonce was set');
};

subtest_buffered no_new_nonce => sub {
	_reset_data();
	my $takeover_LE_Message = Test2::Mock->new(
		class    => 'WWW::LetsEncrypt::Message',
		override => [
			_prep_step => sub { 'noop' },
		],
	);

	my $Response = HTTP::Response->new(429, '', HTTP::Headers->new());
	my $takeover_lwp = Test2::Mock->new(
		class    => 'LWP::UserAgent',
		override => [
			request => sub { return $Response; },
		],
	);
	$Message->_Request(mock_obj(add => [ method => sub { return 'GET' }]));
	$Message->nonce('nonce');

	ok(dies { $Message->do_request() }, 'Properly died during processing.');
	is($Message->nonce, '', 'Nonce was cleared');
};

subtest_buffered _get_nonce_no_nonce => sub {
	_reset_data();
	my $Response = HTTP::Response->new(101, '', HTTP::Headers->new());
	$Message->nonce('NONCE');
	ok(!$Message->_get_nonce($Response), '_get_nonce failed due to lack of nonce');
	is($Message->nonce, '', 'nonce was cleared');
};

done_testing;

