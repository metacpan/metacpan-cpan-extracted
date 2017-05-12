use Test::More;
use Test::Exception;
use Data::Dumper;

use Zabbix::API;

use lib 't/lib';
use Zabbix::API::TestUtils;

if ($ENV{ZABBIX_SERVER}) {

    plan tests => 7;

} else {

    plan skip_all => 'Needs an URL in $ENV{ZABBIX_SERVER} to run tests.';

}

use_ok('Zabbix::API::HostGroup');

my $zabber = Zabbix::API::TestUtils::canonical_login;

my $hostgroups = $zabber->fetch('HostGroup', params => { search => { name => 'Zabbix servers' } });

is(@{$hostgroups}, 1, '... and a host group known to exist can be fetched');

my $zabhost = $hostgroups->[0];

isa_ok($zabhost, 'Zabbix::API::HostGroup',
       '... and that host group');

ok($zabhost->created,
   '... and it returns true to existence tests');

my $new_hostgroup = Zabbix::API::HostGroup->new(root => $zabber,
                                                data => { name => 'Another HostGroup' });

isa_ok($new_hostgroup, 'Zabbix::API::HostGroup',
       '... and a hostgroup created manually');

eval { $new_hostgroup->push };

if ($@) { diag "Caught exception: $@" };

ok($new_hostgroup->created,
   '... and pushing it to the server creates a new hostgroup');

eval { $new_hostgroup->delete };

if ($@) { diag "Caught exception: $@" };

TODO: {

    todo_skip 'Current version of the API does not allow even Super Admins to delete HostGroups', 1;

    ok(!$new_hostgroup->created,
       '... and calling its delete method removes it from the server');

}

eval { $zabber->logout };
