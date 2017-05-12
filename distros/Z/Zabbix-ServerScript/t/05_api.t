use strict;
use warnings;

use Test::More tests => 3;
use Test::Fatal;
use Test::Output;
use Test::MockObject;
use File::Temp;
use Data::Dumper;
use File::Copy;
use File::Path;

use Zabbix::ServerScript;

$ENV{BASENAME} = q(zabbix_server_script_test);
$ENV{ID} = q(zabbix_server_script_test);
Zabbix::ServerScript::_set_logger({ log_filename => q(/tmp/zabbix_server_script_test.log) });

my $dirname = File::Temp::tempdir(q(/tmp/test_lib_dir.XXXXXX), CLEANUP => 1);
File::Path::mkpath(qq($dirname/Zabbix/ServerScript));
copy($INC{q(Zabbix/ServerScript/DefaultConfig.pm)}, qq($dirname/Zabbix/ServerScript/Config.pm));
push @INC, $dirname;
require_ok(q(Zabbix::ServerScript::API));

subtest q(Check config) => sub {
	my $res;
	my $api;
	my $old_api_config = $Zabbix::ServerScript::Config->{api};

	$Zabbix::ServerScript::Config->{api} = undef;
	ok(exception { Zabbix::ServerScript::_set_api(q(rw)) }, q(Throws exception if 'api' section is not defined in global config));

	$Zabbix::ServerScript::Config->{api} = {};
	ok(exception { Zabbix::ServerScript::_set_api(q(rw)) }, q(Throws exception if 'url' is not present in 'api' section in global config));

	$Zabbix::ServerScript::Config->{api} = { url => q(https://zabbix.example.com) };
	ok(exception { Zabbix::ServerScript::_set_api(q(rw)) }, q(Throws exception if requested API credentials are not defined));

	$Zabbix::ServerScript::Config->{api} = {
		url => q(https://zabbix.example.com),
		rw => {
			login => q(user),
			password => undef,
		},
	};
	ok(exception { Zabbix::ServerScript::_set_api(q(rw)) }, q(Throws exception if password is not defined for requested API credentials));

	$Zabbix::ServerScript::Config->{api} = {
		url => q(https://zabbix.example.com),
		rw => {
			login => undef,
			password => q(password),
		},
	};
	ok(exception { Zabbix::ServerScript::_set_api(q(rw)) }, q(Throws exception if login is not defined for requested API credentials));
};

subtest q(Mock object) => sub {
	my $is_error;
	my $zx_api;

	my $response = Test::MockObject->new();
	$response->mock(
		is_error => sub {
			$is_error,
		});

	my $ua = Test::MockObject->new();
	$ua->fake_new(q(LWP::UserAgent));
	$ua->mock(
		post => sub {
			$response,
		}
	);
	$ua->mock(timeout => sub { 1; });

	$Zabbix::ServerScript::Config->{api} = {
		url => q(https://zabbix.example.com),
		rw => {
			login => q(user),
			password => q(password),
		},
	};

	$is_error = 1;
	like(exception { Zabbix::ServerScript::_set_api(q(rw)) }, qr(Cannot make request), q(Die at login failure));

	$is_error = 0;
	$response->mock(
		content => sub { q({
			"jsonrpc": "2.0",
			"error": {
				"code": -32602,
				"message": "Message.",
				"data": "Data."
			},
			"id": 1
		}) }
	);
	like(exception { Zabbix::ServerScript::_set_api(q(rw)) }, qr(Message\..+Data\.), q(Die if error is returned));

	$response->mock(
		content => sub { q({
			"jsonrpc": "2.0",
			"result": "0424bd59b807674191e7d77572075f33",
			"id": 1
		}) }
	);
	$zx_api = Zabbix::ServerScript::_set_api(q(rw));
	is($zx_api->{auth}, q(0424bd59b807674191e7d77572075f33), q(Initialized with correct auth code));

	$zx_api = undef;
};

unlink(q(/tmp/zabbix_server_script_test.log));
rmdir($dirname);
done_testing;
