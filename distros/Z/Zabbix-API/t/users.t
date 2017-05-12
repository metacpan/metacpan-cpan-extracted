use strict;
use warnings;
use 5.010;

use Test::More;
use Test::Exception;
use Data::Dumper;

use Zabbix::API;

use lib 't/lib';
use Zabbix::API::TestUtils;

if ($ENV{ZABBIX_SERVER}) {

    plan tests => 18;

} else {

    plan skip_all => 'Needs an URL in $ENV{ZABBIX_SERVER} to run tests.';

}

use_ok('Zabbix::API::User');

my $zabber = Zabbix::API::TestUtils::canonical_login;

ok(my $default = $zabber->fetch('User', params => { search => { alias => $ENV{ZABBIX_API_USER} } })->[0],
   '... and a user known to exist can be fetched');

isa_ok($default, 'Zabbix::API::User',
       '... and that user');

ok($default->created,
   '... and it returns true to existence tests');

my $user = Zabbix::API::User->new(root => $zabber,
                                  data => { alias => 'luser',
                                            name => 'Louis',
                                            surname => 'User' });

isa_ok($user, 'Zabbix::API::User',
       '... and a user created manually');

lives_ok(sub { $user->push }, '... and pushing a new user works');

ok($user->created, '... and the pushed user returns true to existence tests (id is '.$user->id.')');

$user->data->{name} = 'Louise';

$user->push;

is($user->data->{name}, 'Louise',
   '... and pushing a modified user updates its data on the server');

# testing update by collision
my $same_user = Zabbix::API::User->new(root => $zabber,
                                       data => { alias => 'luser',
                                                 name => 'Loki',
                                                 surname => 'Usurper' });

lives_ok(sub { $same_user->push }, '... and pushing an identical user works');

ok($same_user->created, '... and the pushed identical user returns true to existence tests');

$user->pull;

is($user->data->{name}, 'Loki',
   '... and the modifications on the identical user are pushed');

is($same_user->id, $user->id, '... and the identical user has the same id ('.$user->id.')');

is_deeply($user->usergroups, [], '... and the newly-created user belongs to no groups');

lives_ok(sub { $user->add_to_usergroup('Guests') },
         '... and adding a user to a usergroup works');

is_deeply([ map { $_->data->{name} } @{$user->usergroups} ], ['Guests'],
          '... and the newly-created user can be added to groups');

lives_ok(sub { $user->delete }, '... and deleting a user works');

ok(!$user->created,
   '... and deleting a user removes it from the server');

ok(!$same_user->created,
   '... and the identical user is removed as well') or $same_user->delete;

eval { $zabber->logout };
