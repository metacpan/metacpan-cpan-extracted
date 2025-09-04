use strict;
use warnings;
use 5.010;
use Carp;
use autodie;
use utf8;

use Test::More;
use Test::Exception;
use Data::Dumper;

use Zabbix7::API;
use Zabbix7::API::Trigger;

use lib 't/lib';
use Zabbix7::API::TestUtils;

use Zabbix7::API::Action qw/ACTION_EVENTSOURCE_TRIGGERS ACTION_CONDITION_TYPE_TRIGGER_NAME ACTION_CONDITION_OPERATOR_LIKE ACTION_OPERATION_TYPE_MESSAGE ACTION_EVAL_TYPE_AND/;

unless ($ENV{ZABBIX_SERVER}) {
    plan skip_all => 'Needs an URL in $ENV{ZABBIX_SERVER} to run tests.';
}

my $zabber = Zabbix7::API::TestUtils::canonical_login;

my $actions = $zabber->fetch('Action', params => { search => { name => 'Auto discovery. Linux servers.' } });

is(@{$actions}, 1, '... and an action known to exist can be fetched');

my $action = $actions->[0];

isa_ok($action, 'Zabbix7::API::Action',
       '... and that action');

ok($action->exists,
   '... and it returns true to existence tests');

my $new_trigger = Zabbix7::API::Trigger->new(root => $zabber,
                                             data => { description => 'Another Trigger',
                                                       expression => '{Zabbix server:system.uptime.last(0)}<600', });

SKIP: {

    eval { $new_trigger->create };

    if (my $error = $@) {
        diag "Caught exception: $@";
        if ($error =~ m/\[ CTrigger::create \] No permissions !/) {
            # We're dealing with an old version of the API (this happens
            # even when the API user is a superadmin...)
            skip 'This version of the API has a bugged trigger creation method', 4;
        }
    };

    my $any_media_type = $zabber->fetch_single('MediaType', params => { limit => 1 });
    my $any_user = $zabber->fetch_single('User', params => { limit => 1 });

    my $new_action = Zabbix7::API::Action->new(root => $zabber,
                                               data => { name => 'Another Action',
                                                         esc_period => 120,
                                                         eventsource => ACTION_EVENTSOURCE_TRIGGERS,
                                                         evaltype => ACTION_EVAL_TYPE_AND,
                                                         conditions => [ { conditiontype => ACTION_CONDITION_TYPE_TRIGGER_NAME,
                                                                           operator => ACTION_CONDITION_OPERATOR_LIKE,
                                                                           value => $new_trigger->data->{description} } ],
                                                         operations => [ { operationtype => ACTION_OPERATION_TYPE_MESSAGE,
                                                                           opmessage => { default_msg => 1,
                                                                                          mediatypeid => $any_media_type->id },
                                                                           opmessage_usr => [ { userid => $any_user->id } ] } ]
                                               });

    isa_ok($new_action, 'Zabbix7::API::Action',
           '... and an action created manually');

    lives_ok(sub { $new_action->create },
             q{... and creating an action works});

    ok($new_action->exists,
       '... and pushing it to the server creates a new action');

    my $actions_again = $zabber->fetch('Action', params => { search => { name => 'Another Action' } });

    is(@{$actions_again}, 1, '... and the just-created action can be fetched');

    eval { $new_action->delete };
    $new_trigger->delete;

    if ($@) { diag "Caught exception: $@" };

    ok(!$new_action->exists,
       '... and calling its delete method removes it from the server');

}

eval { $zabber->logout };

done_testing;
