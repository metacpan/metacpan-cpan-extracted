use strict;
use warnings;
use 5.010;

use Test::More;
use Test::Exception;
use Data::Dumper;

use Zabbix7::API;
use Zabbix7::API::UserGroup;
use Zabbix7::API::User;

use lib 't/lib';
use Zabbix7::API::TestUtils;

unless ($ENV{ZABBIX_SERVER}) {
    plan skip_all => 'Needs an URL in $ENV{ZABBIX_SERVER} to run tests.';
}

my $zabber = Zabbix7::API::TestUtils::canonical_login;

ok(my $default = $zabber->fetch('UserGroup', params => { search => { name => 'Guests' } })->[0],
   '... and a usergroup known to exist can be fetched');

isa_ok($default, 'Zabbix7::API::UserGroup',
       '... and that usergroup');

ok($default->exists,
   '... and it returns true to existence tests');

my $usergroup = Zabbix7::API::UserGroup->new(root => $zabber,
                                             data => { name => 'Mad Cats' });

isa_ok($usergroup, 'Zabbix7::API::UserGroup',
       '... and a usergroup created manually');

lives_ok(sub { $usergroup->create }, '... and pushing a new usergroup works');

ok($usergroup->exists, '... and the pushed usergroup returns true to existence tests (id is '.$usergroup->id.')');

$usergroup->data->{name} = 'Mad Unicorns';

$usergroup->update;
$usergroup->pull;

is($usergroup->data->{name}, 'Mad Unicorns',
   '... and pushing a modified usergroup updates its data on the server');

lives_ok(sub { $usergroup->delete }, '... and deleting a usergroup works');

ok(!$usergroup->exists,
   '... and deleting a usergroup removes it from the server');

eval { $zabber->logout };

done_testing;
