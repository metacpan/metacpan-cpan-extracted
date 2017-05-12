use strict;
use warnings;

use Test::More;
use Test::Exception;
use Data::Dumper;

use Zabbix::API;
use Zabbix::API::Trigger;

use lib 't/lib';
use Zabbix::API::TestUtils;

if ($ENV{ZABBIX_SERVER}) {

    plan tests => 8;

} else {

    plan skip_all => 'Needs an URL in $ENV{ZABBIX_SERVER} to run tests.';

}

use_ok('Zabbix::API::Action');
use Zabbix::API::Action qw/ACTION_EVENTSOURCE_TRIGGERS ACTION_CONDITION_TYPE_TRIGGER_NAME ACTION_CONDITION_OPERATOR_LIKE ACTION_OPERATION_TYPE_MESSAGE ACTION_EVAL_TYPE_AND/;

my $zabber = Zabbix::API::TestUtils::canonical_login;

my $actions = $zabber->fetch('Action', params => { search => { name => 'Auto discovery. Linux servers.' } });

is(@{$actions}, 1, '... and an action known to exist can be fetched');

my $action = $actions->[0];

isa_ok($action, 'Zabbix::API::Action',
       '... and that action');

ok($action->created,
   '... and it returns true to existence tests');

my $new_trigger = Zabbix::API::Trigger->new(root => $zabber,
                                            data => { description => 'Another Trigger',
                                                      expression => '{Zabbix Server:system.uptime.last(0)}<600', });

$new_trigger->push;

my $new_action = Zabbix::API::Action->new(root => $zabber,
                                          data => { name => 'Another Action',
                                                    eventsource => ACTION_EVENTSOURCE_TRIGGERS,
                                                    evaltype => ACTION_EVAL_TYPE_AND,
                                                    conditions => [ { conditiontype => ACTION_CONDITION_TYPE_TRIGGER_NAME,
                                                                      operator => ACTION_CONDITION_OPERATOR_LIKE,
                                                                      value => $new_trigger->data->{description} } ],
                                                    operations => [ { operationtype => ACTION_OPERATION_TYPE_MESSAGE,
                                                                      shortdata => '{TRIGGER.NAME}: {STATUS}',
                                                                      longdata => '{TRIGGER.NAME}: {STATUS}' } ]
                                                    });

isa_ok($new_action, 'Zabbix::API::Action',
       '... and an action created manually');

eval { $new_action->push };

if ($@) { diag "Caught exception: $@" };

ok($new_action->created,
   '... and pushing it to the server creates a new action');

my $actions_again = $zabber->fetch('Action', params => { search => { name => 'Another Action' } });

is(@{$actions_again}, 1, '... and the just-created action can be fetched');

eval { $new_action->delete };
$new_trigger->delete;

if ($@) { diag "Caught exception: $@" };

ok(!$new_action->created,
   '... and calling its delete method removes it from the server');

eval { $zabber->logout };
