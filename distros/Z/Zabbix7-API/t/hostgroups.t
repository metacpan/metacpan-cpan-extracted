use strict;
use warnings;
use 5.010;
use Carp;
use autodie;
use utf8;

use Test::More;

use Zabbix7::API;
use Zabbix7::API::HostGroup;

use lib 't/lib';
use Zabbix7::API::TestUtils;

unless ($ENV{ZABBIX_SERVER}) {
    plan skip_all => 'Needs an URL in $ENV{ZABBIX_SERVER} to run tests.';
}

my $zabber = Zabbix7::API::TestUtils::canonical_login;

my $hostgroups = $zabber->fetch('HostGroup', params => { search => { name => 'Zabbix servers' } });

is(@{$hostgroups}, 1, '... and a host group known to exist can be fetched');

my $zabhostgroup = $hostgroups->[0];

isa_ok($zabhostgroup, 'Zabbix7::API::HostGroup',
       '... and that host group');

ok($zabhostgroup->exists,
   '... and it returns true to existence tests');

my $hosts = $zabhostgroup->hosts;
is(scalar(@{$hosts}), 1,
   q{... and it has a host});
isa_ok($hosts->[0], 'Zabbix7::API::Host',
       q{... and that host});
is_deeply([ map { $_->id } @{$hosts->[0]->hostgroups} ], [ $zabhostgroup->id ],
          q{... and the host does belong to the hostgroup});

my $new_hostgroup = Zabbix7::API::HostGroup->new(root => $zabber,
                                                 data => { name => 'Another HostGroup' });

isa_ok($new_hostgroup, 'Zabbix7::API::HostGroup',
       '... and a hostgroup created manually');

eval { $new_hostgroup->create };

if ($@) { diag "Caught exception: $@" };

ok($new_hostgroup->exists,
   '... and pushing it to the server creates a new hostgroup');

eval { $new_hostgroup->delete };

if ($@) { diag "Caught exception: $@" };

TODO: {
    todo_skip 'Current version of the API does not allow even Super Admins to delete HostGroups', 1;
    ok(!$new_hostgroup->exists,
       '... and calling its delete method removes it from the server');
}

eval { $zabber->logout };

done_testing;
