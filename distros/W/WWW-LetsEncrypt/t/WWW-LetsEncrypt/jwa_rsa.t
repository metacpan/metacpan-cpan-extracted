use strict;
use warnings;

use Test2::Bundle::Extended;
use Test2::Tools::Exception qw/dies/;
use Test2::Tools::Subtest qw/subtest_buffered/;

use JSON;
use MIME::Base64;
use WWW::LetsEncrypt::JWK::RSA;

my $unsigned_message = 'A Test Message';
my $private_key =<<'END';
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
my $rsa_serialized_key = {
	n => "ofgWCuLjybRlzo0tZWJjNiuSfb4p4fAkd_wWJcyQoTbji9k0l8W26mPddxHmfHQp-Vaw-4qPCJrcS2mJPMEzP1Pt0Bm4d4QlL-yRT-SFd2lZS-pCgNMsD1W_YpRPEwOWvG6b32690r2jZ47soMZo9wGzjb_7OMg0LOL-bSf63kpaSHSXndS5z5rexMdbBYUsLA9e-KXBdQOS-UTo7WTBEMa2R2CapHg665xsmtdVMTBQY4uDZlxvb3qCo5ZwKh9kG4LT6_I5IhlJH7aGhyxXFvUK-DWNmoudF8NAco9_h9iaGNj8q2ethFkMLs91kzk2PAcDTW9gb54h4FRWyuXpoQ",
	e => "AQAB",
	d => "Eq5xpGnNCivDflJsRQBXHx1hdR1k6Ulwe2JZD50LpXyWPEAeP88vLNO97IjlA7_GQ5sLKMgvfTeXZx9SE-7YwVol2NXOoAJe46sui395IW_GO-pWJ1O0BkTGoVEn2bKVRUCgu-GjBVaYLU6f3l9kJfFNS3E0QbVdxzubSu3Mkqzjkn439X0M_V51gfpRLI9JYanrC4D4qAdGcopV_0ZHHzQlBjudU2QvXt4ehNYTCBr6XCLQUShb1juUO1ZdiYoFaFQT5Tw8bGUl_x_jTj3ccPDVZFD9pIuhLhBOneufuBiB4cS98l2SR_RQyGWSeWjnczT0QU91p1DhOVRuOopznQ",
	p => "4BzEEOtIpmVdVEZNCqS7baC4crd0pqnRH_5IB3jw3bcxGn6QLvnEtfdUdiYrqBdss1l58BQ3KhooKeQTa9AB0Hw_Py5PJdTJNPY8cQn7ouZ2KKDcmnPGBY5t7yLc1QlQ5xHdwW1VhvKn-nXqhJTBgIPgtldC-KDV5z-y2XDwGUc",
	q => "uQPEfgmVtjL0Uyyx88GZFF1fOunH3-7cepKmtH4pxhtCoHqpWmT8YAmZxaewHgHAjLYsp1ZSe7zFYHj7C6ul7TjeLQeZD_YwD66t62wDmpe_HlB-TnBA-njbglfIsRLtXlnDzQkv5dTltRJ11BKBBypeeF6689rjcJIDEz9RWdc",
	dp => "BwKfV3Akq5_MFZDFZCnW-wzl-CCo83WoZvnLQwCTeDv8uzluRSnm71I3QCLdhrqE2e9YkxvuxdBfpT_PI7Yz-FOKnu1R6HsJeDCjn12Sk3vmAktV2zb34MCdy7cpdTh_YVr7tss2u6vneTwrA86rZtu5Mbr1C1XsmvkxHQAdYo0",
	dq => "h_96-mK1R_7glhsum81dZxjTnYynPbZpHziZjeeHcXYsXaaMwkOlODsWa7I9xXDoRwbKgB719rrmI2oKr6N3Do9U0ajaHF-NKJnwgjMd2w9cjz3_-kyNlxAr2v4IKhGNpmM5iIgOS1VZnOZ68m6_pbLBSp3nssTdlqvd0tIiTHU",
	qi => "IYd7DHOhrWvxkwPQsRM2tOgrjbcrfvtQJipd-DlcxyVuuM9sQLdgjVk2oy26F0EmpScGLq2MowX7fhd_QJQ3ydy5cY7YIBi87w93IKLEdfnbJtoOPLUW0ITrJReOgo1cq9SbsxYawBgfp_gh6A5603k2-ZQwVK0JKSHuLFkuQ3U",
};

subtest_buffered loading_crt => sub {
	my $signed_message = 'N1Pkf2+Hc7yNsmm4AOlTvs6dkyWFm+vCvRJ+l7GB5UoGKX0bucLs3jvQJlf/50NcxiE1qkVTj3UkHmN8D9YW650dgDAMidVe02k9DudCrSJsnSq5fHjJeAFJ35T0GeljU0/QvZpv05H1gGZYbJI4LygIqC8ThuCNeDeXd3bpmus=';
	my $Obj = WWW::LetsEncrypt::JWK::RSA::load_cert({
		private_key => $private_key,
	});
	is($signed_message, encode_base64($Obj->sign($unsigned_message), ''), 'Created a matching signature');
};

subtest_buffered loading_params => sub {
	my $signed_message = "TUrc6KccqGMKt+oUOHgMKV6huE2orV4qC64rMXqwVu1AR+P2aN5LOLL+PH1zNhfHZIo3miwRJ6BwpNn5YIE6KmOHMs2gTVySzgJ9KUDm3j2Rf9kAFVlUHMPR1Pn9knhbjYwQlvVvh1XVYCag3WeSSfukQuHt+hEiSj2ZxcUGmS143NAWJWMPGvQvyfs4ljKJcB8zTbbq4vWRUg6e6tcCSJ0r+aC8+pAvcIswLPvENa6xEcQNkaC4c+GDhbO12ihdynNnWT545Y1fvqvlsYxf1jCNMI1igOXVSbCZnAZTVjlc+vWkqFHzDSzGRYj8+PwHzTOD9Sk6H7hHBCUxbcB+xA==";
	my $Obj = WWW::LetsEncrypt::JWK::RSA::load_parameters({
		parameters => $rsa_serialized_key,
	});
	is(encode_base64($Obj->sign($unsigned_message), ''), $signed_message, 'Created a matching signature');
};

subtest_buffered generate_new => sub {
	my $Obj = WWW::LetsEncrypt::JWK::RSA::generate_new(2048, '1');
	ok(!!$Obj, 'Properly generated a new object');
};

subtest_buffered serializing_publickey => sub {
	my $JWK = WWW::LetsEncrypt::JWK::RSA::load_parameters({
		parameters => $rsa_serialized_key,
	});

	my $test_serialized_output = $JWK->serialize_public_key();
	like(
		{
			%$rsa_serialized_key,
			alg => 'RS256',
			kty => 'RSA',
		},
		$test_serialized_output,
		'Properly serialized the public key.'
	);
};

subtest_buffered hashing_modes => sub {
	my $Obj;
	for my $alg (qw(RS256 RS384 RS512)) {
		my $Obj = WWW::LetsEncrypt::JWK::RSA::load_cert({
			private_key => $private_key,
			alg         => $alg,
		});
		is($Obj->alg, $alg, 'Properly set algorihtm');
	}
	for my $alg (qw(HS256 RS1000 RS1024)) {
		ok(
			dies {
				WWW::LetsEncrypt::JWK::RSA::load_cert({
					private_key => $private_key,
					alg         => $alg,
				});
			},
			"Properly died when passed an invalid or mismatched ($alg)."
		);
	}
};

subtest_buffered missing_parameters => sub {
	my %cert_hash = (
		private_key => $private_key,
	);

	for my $removed_item (keys %cert_hash) {
		my %testing_hash = %cert_hash;
		delete $testing_hash{$removed_item};
		ok(
			dies {
				WWW::LetsEncrypt::JWK::RSA::load_cert(\%testing_hash);
			},
			"Shouldn't create object when $removed_item is missing."
		);
	}

	my %params_hash = (
		parameters => $rsa_serialized_key,
	);

	for my $removed_item (keys %params_hash) {
		my %testing_hash = %params_hash;
		delete $testing_hash{$removed_item};
		ok(
			dies {
				WWW::LetsEncrypt::JWK::RSA::load_parameters(\%testing_hash);
			},
			"Shouldn't create object when $removed_item is missing."
		);
	}
};

subtest_buffered thumbprint_output => sub {
	my $Obj = WWW::LetsEncrypt::JWK::RSA::load_cert({
		private_key => $private_key,
	});
	is($Obj->thumbprint, 'i-0IIn3UqonpV2r6_bOeVnizN97F4zwG38DeBfMeJv8', 'Generated the correct thumbprint.');
};

subtest_buffered private_key_output => sub {
	my $Obj = WWW::LetsEncrypt::JWK::RSA::load_cert({
		private_key => $private_key,
	});
	is($Obj->get_privatekey_string(), $private_key, 'Correctly exported private key');
};

done_testing;
