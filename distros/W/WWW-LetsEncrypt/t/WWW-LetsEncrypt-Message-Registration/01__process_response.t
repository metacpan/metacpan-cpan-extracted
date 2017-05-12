use strict;
use warnings;

use Test2::Bundle::Extended;
use Test2::Tools::Subtest qw/subtest_buffered/;

use HTTP::Response;
use HTTP::Headers;
use JSON;
use WWW::LetsEncrypt::JWK::RSA;
use WWW::LetsEncrypt::Message::Registration;

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
my $mock_contact_info = ['mailto:cert-admin@example.com', 'tel:+1205551212'];

sub _reset_data {
	$Message = WWW::LetsEncrypt::Message::Registration->new({
		JWK       => $JWK,
		agreement => 1,
		contact   => $mock_contact_info,

	});
}

subtest_buffered properly_created => sub {
	_reset_data;
	my $response_body_ref = {
		key     => 'PREDICTABLE_KEY',
		contact => $mock_contact_info
	};
	my $Response = HTTP::Response->new(
		201,
		'',
		HTTP::Headers->new(),
		encode_json($response_body_ref),
	);
	$Message->_prep_step();

	my $processed_response = $Message->_process_response($Response);
	is($Message->_step, 'update', 'Properly set the next step to "update"');

	# Don't care about the actual value, merely the truthiness of them.
	ok($processed_response->{successful}, 'Step was reported to be successful');
	ok(!$processed_response->{already_registered}, 'already_registered flag was not set.');
	ok(!$processed_response->{error}, 'No error encountered');
};

subtest_buffered already_registered => sub {
	_reset_data;
	my $Response = HTTP::Response->new(
		409,
		'CONFLICT',
		HTTP::Headers->new(),
		encode_json({element => 1})
	);
	$Message->_prep_step();

	my $processed_response = $Message->_process_response($Response);
	is($Message->_step, 'new-reg', 'Step was not changed from "new-reg" to "update"');
	ok(!$processed_response->{successful}, 'Step was not successful');
	ok($processed_response->{already_registered}, 'Reported already_registered');
	ok(!$processed_response->{error}, 'No unrecoverably error was encountered');
};

subtest_buffered unrecoverable_error => sub {
	_reset_data;
	my $Response = HTTP::Response->new(
		404,
		'NOT_FOUND',
		HTTP::Headers->new(),
		'Cannot find.'
	);

	my $processed_response = $Message->_process_response($Response);
	ok($processed_response->{error}, 'Error reported.');
};

done_testing;

