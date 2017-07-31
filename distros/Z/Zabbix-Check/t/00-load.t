use strict;
use warnings;

use Test::More;


BEGIN { use_ok('Zabbix::Check') }
BEGIN { use_ok('Zabbix::Check::Disk') }
BEGIN { use_ok('Zabbix::Check::Supervisor') }
BEGIN { use_ok('Zabbix::Check::RabbitMQ') }
BEGIN { use_ok('Zabbix::Check::Systemd') }
BEGIN { use_ok('Zabbix::Check::Time') }
BEGIN { use_ok('Zabbix::Check::Redis') }


done_testing;
