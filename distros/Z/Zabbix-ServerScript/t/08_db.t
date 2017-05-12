use strict;
use warnings;

use Test::More tests => 1;
use Test::Fatal;
use Test::Output;
use Test::MockModule;
use File::Temp;
use Data::Dumper;
use Storable;
use Capture::Tiny ':all';

use Zabbix::ServerScript;

Zabbix::ServerScript::init({ log_filename => q(/tmp/zabbix_server_script_test.log) });

subtest q(Check connection to database) => sub {
	my $module = Test::MockModule->new('DBI');
	my $res;
	$module->mock(q(connect), sub { return $res; });
	like(exception { Zabbix::ServerScript::connect_to_db() }, qr(dbname is not defined), q(Throw exception if dbname is not defined));
	like(exception { Zabbix::ServerScript::connect_to_db(q(test)) }, qr(Failed to connect), q(Die at connect failure));
	$res = 1;
	ok(Zabbix::ServerScript::connect_to_db(q(test)), q(Successfully connect to DB));
};

unlink(q(/tmp/zabbix_server_script_test.log));
done_testing;
