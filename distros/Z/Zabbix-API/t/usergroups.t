use strict;
use warnings;
use 5.010;

use Test::More;
use Test::Exception;
use Data::Dumper;

use Zabbix::API;
use Zabbix::API::User;

use lib 't/lib';
use Zabbix::API::TestUtils;

if ($ENV{ZABBIX_SERVER}) {

    plan tests => 21;

} else {

    plan skip_all => 'Needs an URL in $ENV{ZABBIX_SERVER} to run tests.';

}

use_ok('Zabbix::API::UserGroup');

my $zabber = Zabbix::API::TestUtils::canonical_login;

ok(my $default = $zabber->fetch('UserGroup', params => { search => { name => 'API access' } })->[0],
   '... and a usergroup known to exist can be fetched');

isa_ok($default, 'Zabbix::API::UserGroup',
       '... and that usergroup');

ok($default->created,
   '... and it returns true to existence tests');

my $usergroup = Zabbix::API::UserGroup->new(root => $zabber,
                                            data => { name => 'Mad Cats' });

isa_ok($usergroup, 'Zabbix::API::UserGroup',
       '... and a usergroup created manually');

lives_ok(sub { $usergroup->push }, '... and pushing a new usergroup works');

ok($usergroup->created, '... and the pushed usergroup returns true to existence tests (id is '.$usergroup->id.')');

$usergroup->data->{name} = 'Mad Unicorns';

$usergroup->push;

is($usergroup->data->{name}, 'Mad Unicorns',
   '... and pushing a modified usergroup updates its data on the server');

# testing update by collision
my $same_usergroup = Zabbix::API::UserGroup->new(root => $zabber,
                                                 data => { name => 'Mad Unicorns' });

lives_ok(sub { $same_usergroup->push }, '... and pushing an identical usergroup works');

ok($same_usergroup->created, '... and the pushed identical usergroup returns true to existence tests');

is($same_usergroup->id, $usergroup->id, '... and the identical usergroup has the same id ('.$usergroup->id.')');

# is_deeply($usergroup->users, [], '... and the newly-created usergroup contains no users');

# my $user = Zabbix::API::User->new(root => $zabber,
#                                   data => { alias => 'luser',
#                                             name => 'Louis',
#                                             surname => 'User' });

# $usergroup->users([ { user => $user } ]);

# lives_ok(sub { $usergroup->push }, '... and adding a user works');
# $usergroup->pull;

# is_deeply([ map { $_->id } @{$usergroup->users} ], [ $user->id ],
#           '... and the user is on the server now');

# $usergroup->users([ { userid => $user->id } ]);

# lives_ok(sub { $usergroup->push }, '... and adding a user by id works');
# $usergroup->pull;

# is_deeply([ map { $_->id } @{$usergroup->users} ], [ $user->id ],
#           '... and the user is on the server now');

# is_deeply([ map { $_->id } @{$user->usergroups} ], [ $usergroup->id ],
#           '... and the user in the usergroup has a usergroup now');

# lives_ok(sub { $usergroup->delete }, '... and deleting a usergroup works');

ok(!$usergroup->created,
   '... and deleting a usergroup removes it from the server');

ok(!$same_usergroup->created,
   '... and the identical usergroup is removed as well') or $same_usergroup->delete;

# is_deeply($user->usergroups, [],
#           '... and the user in the usergroup has no usergroup now');

# $user->delete;

eval { $zabber->logout };
