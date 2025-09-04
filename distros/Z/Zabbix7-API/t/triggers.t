use strict;
use warnings;

use Test::More;
use Test::Exception;
use Data::Dumper;

use Zabbix7::API;
use Zabbix7::API::Trigger;

use lib 't/lib';
use Zabbix7::API::TestUtils;

unless ($ENV{ZABBIX_SERVER}) {
    plan skip_all => 'Needs an URL in $ENV{ZABBIX_SERVER} to run tests.';
}

my $zabber = Zabbix7::API::TestUtils::canonical_login;

my $host = $zabber->fetch('Host', params => { host => 'Zabbix Server',
                                              search => { host => 'Zabbix Server' } })->[0];

my $item = $zabber->fetch('Item', params => { host => 'Zabbix Server',
                                              search => { key_ => 'system.uptime' } })->[0];

my $triggers = $zabber->fetch('Trigger', params => { search => { description => '{HOST.NAME} has just been restarted' },
                                                     hostids => [ $host->id ],
                                                     templated => 0 });

is(@{$triggers}, 1, '... and a trigger known to exist can be fetched');

my $trigger = $triggers->[0];

isa_ok($trigger, 'Zabbix7::API::Trigger',
       '... and that trigger');

ok($trigger->exists,
   '... and it returns true to existence tests');

my $new_trigger = Zabbix7::API::Trigger->new(root => $zabber,
                                            data => { description => 'Another Trigger',
                                                      expression => '{Zabbix server:system.uptime.last(0)}<600', });

isa_ok($new_trigger, 'Zabbix7::API::Trigger',
       '... and a trigger created manually');

SKIP: {

    eval { $new_trigger->create };

    if (my $error = $@) {
        diag "Caught exception: $@";
        if ($error =~ m/\[ CTrigger::create \] No permissions !/) {
            # We're dealing with an old version of the API (this happens
            # even when the API user is a superadmin...)
            skip 'This version of the API has a bugged trigger creation method', 5;
        }
    };

    ok($new_trigger->exists,
       '... and pushing it to the server creates a new trigger');

    lives_ok(sub { $new_trigger->delete },
             q{... and the trigger can be deleted});

    ok(!$new_trigger->exists,
       '... and calling its delete method removes it from the server');

}

eval { $zabber->logout };

done_testing;
