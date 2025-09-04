use strict;
use warnings;
use 5.010;

use Test::More;
use Test::Exception;
use Data::Dumper;

use Zabbix7::API;
use Zabbix7::API::User;

use lib 't/lib';
use Zabbix7::API::TestUtils;

unless ($ENV{ZABBIX_SERVER}) {
    plan skip_all => 'Needs an URL in $ENV{ZABBIX_SERVER} to run tests.';
}

my $zabber = Zabbix7::API::TestUtils::canonical_login;

ok(my $default = $zabber->fetch_single('User', params => { filter => { alias => Zabbix7::API::TestUtils::canonical_username() } }),
   '... and a user known to exist can be fetched');

isa_ok($default, 'Zabbix7::API::User',
       '... and that user');

ok($default->exists,
   '... and it returns true to existence tests');

my $guest_group = $zabber->fetch_single('UserGroup', params => { search => { name => 'Guests' } });

my $user = Zabbix7::API::User->new(root => $zabber,
                                   data => { alias => 'luser',
                                             passwd => 'spy',
                                             usrgrps => { usrgrpid => $guest_group->id },
                                             name => 'Louis',
                                             surname => 'User' });

isa_ok($user, 'Zabbix7::API::User',
       '... and a user created manually');

lives_ok(sub { $user->create }, '... and pushing a new user works');

ok($user->exists, '... and the pushed user returns true to existence tests (id is '.$user->id.')');

$user->data->{name} = 'Louise';

$user->update;
$user->pull;

is($user->data->{name}, 'Louise',
   '... and pushing a modified user updates its data on the server');

lives_ok(sub { $user->add_to_usergroup('Disabled') },
         '... and adding a user to a usergroup works');

my $disabled_group = $zabber->fetch_single('UserGroup', params => { search => { name => 'Disabled' } });

is_deeply([ map { $_->data->{alias} } @{$disabled_group->users} ], ['luser'],
          '... and the newly-created user can be added to groups');

lives_ok(sub { $user->delete }, '... and deleting a user works');

ok(!$user->exists,
   '... and deleting a user removes it from the server');

eval { $zabber->logout };

done_testing;
