use strict;
use warnings;

use Test::More tests => 1;
use Test::Fatal;
use Test::MockModule;
use Data::Dumper;
use File::Temp;
use Carp;

my $exit_called = 0;
BEGIN {
	*CORE::GLOBAL::exit = sub {
		croak(qq(Exit called) . Dumper(@_));
	};
}
my $term = Test::MockModule->new(q(Term::UI));
use Zabbix::ServerScript;

subtest q(Test config creation) => sub {

	my $module_dir;
	$term->mock(
		get_reply => sub {
			return $module_dir;
		},
	);

	my $opt = {
		console => 0,
	};

	$module_dir = File::Temp::tempdir(q(/tmp/test_module_dir.XXXXXX), CLEANUP => 1);
	rmdir($module_dir);
	like(exception { Zabbix::ServerScript::create_config($opt) }, qr(Wrong directory), q(Throws an exception if provided directory is wrong));

	$module_dir = File::Temp::tempdir(q(/tmp/test_module_dir.XXXXXX), CLEANUP => 1);
	my $module_filename = qq($module_dir/Config.pm);
	like(exception { Zabbix::ServerScript::create_config($opt) }, qr(Exit called), q(Successfully finishes its job when valid dirs are provided));
	ok(-f $module_filename, q(Config.pm exists in provided dir));
	require_ok($module_filename);

	my $mtime_old = (stat($module_filename))[9];
	my $yn = 0;
	$term->mock(
		ask_yn => sub {
			return $yn;
		}
	);
	like(exception { Zabbix::ServerScript::create_config($opt) }, qr(Exit called), q(Successfully exits if overwrite is not requested));
	my $mtime_new = (stat($module_filename))[9];
	is($mtime_old, $mtime_new, q(File modification time stays the same if overwrite is not requested));

	sleep 1;
	$yn = 1;
	like(exception { Zabbix::ServerScript::create_config($opt) }, qr(Exit called), q(Successfully exits if overwrite is requested));
	$mtime_new = (stat($module_filename))[9];
	isnt($mtime_old, $mtime_new, q(File modification time changes if overwrite is requested));
};

unlink(q(/tmp/zabbix_server_script_test.log));
done_testing;
