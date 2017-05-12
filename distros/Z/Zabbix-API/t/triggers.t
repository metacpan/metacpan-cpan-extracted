use strict;
use warnings;

use Test::More;
use Test::Exception;
use Data::Dumper;

use Zabbix::API;

use lib 't/lib';
use Zabbix::API::TestUtils;

if ($ENV{ZABBIX_SERVER}) {

    plan tests => 10;

} else {

    plan skip_all => 'Needs an URL in $ENV{ZABBIX_SERVER} to run tests.';

}

use_ok('Zabbix::API::Trigger');

my $zabber = Zabbix::API::TestUtils::canonical_login;

my $host = $zabber->fetch('Host', params => { host => 'Zabbix Server',
                                              search => { host => 'Zabbix Server' } })->[0];

my $item = $zabber->fetch('Item', params => { host => 'Zabbix Server',
                                              search => { key_ => 'system.uptime' } })->[0];

my $triggers = $zabber->fetch('Trigger', params => { search => { description => '{HOSTNAME} has just been restarted' },
                                                     hostids => [ $host->id ],
                                                     templated => 0 });

is(@{$triggers}, 1, '... and a trigger known to exist can be fetched');

my $trigger = $triggers->[0];

isa_ok($trigger, 'Zabbix::API::Trigger',
       '... and that trigger');

ok($trigger->created,
   '... and it returns true to existence tests');

my $new_trigger = Zabbix::API::Trigger->new(root => $zabber,
                                            data => { description => 'Another Trigger',
                                                      expression => '{Zabbix Server:system.uptime.last(0)}<600', });

isa_ok($new_trigger, 'Zabbix::API::Trigger',
       '... and a trigger created manually');

eval { $new_trigger->push };

if ($@) { diag "Caught exception: $@" };

ok($new_trigger->created,
   '... and pushing it to the server creates a new trigger');

my $triggers_again = $zabber->fetch('Trigger', params => { search => { description => 'Another Trigger' },
                                                     hostids => [ $host->id ],
                                                     templated => 0 });

is(@{$triggers_again}, 1, '... and the just-created trigger can be fetched');

is_deeply([ map { $_->id } @{$new_trigger->hosts} ], [ $host->id ],
   q{... and the trigger's 'hosts' accessor works});

is_deeply([ map { $_->id } @{$new_trigger->items} ], [ $item->id ],
   q{... and the trigger's 'items' accessor works});

eval { $new_trigger->delete };

if ($@) { diag "Caught exception: $@" };

ok(!$new_trigger->created,
   '... and calling its delete method removes it from the server');

eval { $zabber->logout };
