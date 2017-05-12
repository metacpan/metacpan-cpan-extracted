#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;
use WebService::Pushwoosh;

if (!($ENV{PUSHWOOSH_APP_CODE} && $ENV{PUSHWOOSH_API_TOKEN})) {
	plan skip_all => "Can't run without PUSHWOOSH_APP_CODE and PUSHWOOSH_API_TOKEN set. See TESTING section in the documentation.";
}

my $pw = WebService::Pushwoosh->new(
	app_code => $ENV{PUSHWOOSH_APP_CODE},
	api_token => $ENV{PUSHWOOSH_API_TOKEN}
);

subtest 'Simple message sending' => sub { 
	ok($pw->create_message(content => 'Hello, world!'), "Simple message send did not error");
	ok($pw->create_message(content => 'Hello, world!', devices => ['foo']), "Simple message send with specific device did not error");
};

subtest 'Message deletion' => sub {
	my $message_id = $pw->create_message(content => 'holtzman_effect');
	ok($pw->delete_message(message => $message_id), "delete_message succeeded");
	throws_ok { $pw->delete_message(message => 'foo') } qr/error 210/, q{Got error when deleting non-existent message};
};

subtest 'Register and unregister device' => sub {
	my $device_id = 'TEST_DEVICE'.time;
	ok($pw->register_device(
			push_token => $device_id,
			hwid => $device_id,
			device_type => 7
		), "register_device succeeded");
	ok($pw->unregister_device(hwid => $device_id), "unregister_device succeeded");
};

subtest 'Set tags' => sub {
	my $device_id = 'TEST_DEVICE'.time;
	ok($pw->register_device(
			push_token => $device_id,
			hwid => $device_id,
			device_type => 7
		), "register_device succeeded");
	ok($pw->set_tags(
			hwid => $device_id,
			tags => {
				test_tag => 'emi_chusuk'
			}
		), "set_tags succeeded");
	ok($pw->unregister_device(hwid => $device_id), "unregister_device succeeded");
	throws_ok { $pw->set_tags(
			hwid => $device_id,
			tags => {
				test_tag => 'emi_chusuk'
			}
		) } qr/error 210/, q{Got error when setting tags agains non-existent device}
};

done_testing();
