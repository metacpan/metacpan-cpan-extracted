#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

if (defined $ENV{WWW_AUTHY_TEST_API_KEY_SANDBOX}
	&& defined $ENV{WWW_AUTHY_TEST_API_KEY_LIVE}
	&& defined $ENV{WWW_AUTHY_TEST_CELLPHONE_LIVE}
	&& defined $ENV{WWW_AUTHY_TEST_EMAIL_LIVE}) {

	use_ok('WWW::Authy');

	my $sandbox_authy = WWW::Authy->new($ENV{WWW_AUTHY_TEST_API_KEY_SANDBOX}, sandbox => 1);
	isa_ok($sandbox_authy,'WWW::Authy','sandbox authy object');

	my $sandbox_id = $sandbox_authy->new_user('someone@universe.org','555-123-1234','1');
	ok($sandbox_id,'Checking that user is generated in sandbox');
	ok($sandbox_authy->verify($sandbox_id,'0000000'),'Testing the cheat token of sandbox');

	my $authy = WWW::Authy->new($ENV{WWW_AUTHY_TEST_API_KEY_LIVE});
	isa_ok($authy,'WWW::Authy','authy object');

	my $id = $authy->new_user(
		$ENV{WWW_AUTHY_TEST_EMAIL_LIVE},
		$ENV{WWW_AUTHY_TEST_CELLPHONE_LIVE},
		$ENV{WWW_AUTHY_TEST_COUNTRY_CODE_LIVE}
	);
	ok($id,'Checking that user is generated in live');
	ok(!$authy->verify($id,'000000'),'Testing random token to fail');

} else {
	plan skip_all => 'Not doing live tests without WWW_AUTHY_TEST_API_KEY_SANDBOX, WWW_AUTHY_TEST_API_KEY_LIVE, WWW_AUTHY_TEST_CELLPHONE_LIVE and WWW_AUTHY_TEST_EMAIL_LIVE ENV variable';
}

done_testing;