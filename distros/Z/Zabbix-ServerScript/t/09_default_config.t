use strict;
use warnings;

use Test::More tests => 6;
use Test::Fatal;
use File::Temp;
use Data::Dumper;
use Storable;
use Log::Log4perl;
use English;

use_ok(q(Zabbix::ServerScript::DefaultConfig));

$ENV{BASENAME} = q(zabbix_server_script_test);
$ENV{ID} = $ENV{BASENAME};
$ENV{LOG_FILENAME} = qq(/tmp/$ENV{BASENAME}.log);

subtest q(Check log-related parameters) => sub {
	isnt($Zabbix::ServerScript::Config->{log}, undef, q('log' section is defined));
	is(exception { Log::Log4perl->init($Zabbix::ServerScript::Config->{log}) }, undef, q('log' section contains valid Log4perl initialization data));
	isnt($Zabbix::ServerScript::Config->{log_dir}, undef, q('log_dir' section is defined));
	ok(-d $Zabbix::ServerScript::Config->{log_dir}, q('log_dir' exists));
	ok(-r $Zabbix::ServerScript::Config->{log_dir}, q('log_dir' is readable));
	ok(-w $Zabbix::ServerScript::Config->{log_dir}, q('log_dir' is writable));
	ok(-x $Zabbix::ServerScript::Config->{log_dir}, q('log_dir' is executable));
};

subtest q(Check API-related parameters) => sub {
	isnt($Zabbix::ServerScript::Config->{api}, undef, q('api' section is defined));
	ok(exists $Zabbix::ServerScript::Config->{api}->{url}, q(Provide 'url' example in 'api' section));
	is_deeply($Zabbix::ServerScript::Config->{api}->{rw}, { login => undef, password => undef }, q(Provide 'rw' example in 'api' section));
};

subtest q(Check PID-related parameters) => sub {
	ok(-d $Zabbix::ServerScript::Config->{pid_dir}, q('pid_dir' exists));
	ok(-r $Zabbix::ServerScript::Config->{pid_dir}, q('pid_dir' is readable));
	ok(-w $Zabbix::ServerScript::Config->{pid_dir}, q('pid_dir' is writable));
	ok(-x $Zabbix::ServerScript::Config->{pid_dir}, q('pid_dir' is executable));
};

subtest q(Check cache-related parameters) => sub {
	ok(-d $Zabbix::ServerScript::Config->{cache_dir}, q('cache_dir' exists));
	ok(-r $Zabbix::ServerScript::Config->{cache_dir}, q('cache_dir' is readable));
	ok(-w $Zabbix::ServerScript::Config->{cache_dir}, q('cache_dir' is writable));
	ok(-x $Zabbix::ServerScript::Config->{cache_dir}, q('cache_dir' is executable));
};

subtest q(Check config-related parameters) => sub {
	SKIP: {
		skip q(/usr/local/etc/ does not exist on Mac OS X by default), 3 if $OSNAME eq q(darwin);
		ok(-d $Zabbix::ServerScript::Config->{config_dir}, q('config_dir' exists));
		ok(-r $Zabbix::ServerScript::Config->{config_dir}, q('config_dir' is readable));
		ok(-x $Zabbix::ServerScript::Config->{config_dir}, q('config_dir' is executable));
	}
};

unlink(q(/tmp/zabbix_server_script_test.log));
done_testing;
