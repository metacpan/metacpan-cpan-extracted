use strict;
use warnings;

use Test::More tests => 1;
use Test::Fatal;
use Test::Output;
use File::Temp;
use Data::Dumper;
use Storable;
use Capture::Tiny ':all';

use Zabbix::ServerScript;

Zabbix::ServerScript::init({ log_filename => q(/tmp/zabbix_server_script_test.log) });

subtest q(Check return value) => sub {
	like(exception { Zabbix::ServerScript::return_value() }, qr(Return value is not defined), q(Throw exception if return value is not defined));
	my $stdout = capture {
		fork or Zabbix::ServerScript::return_value(q(test));
		while (wait() != -1) {}
	};
	is($stdout, qq(test\n), q(Write to stdout exactly what is requested));
};

unlink(q(/tmp/zabbix_server_script_test.log));
done_testing;
