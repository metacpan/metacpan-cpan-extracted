use strict;
use Test::More tests => 4;

use WebService::Backlog;
use Encode;

my $backlog = WebService::Backlog->new(
    space    => 'backlog',
    username => 'guest',
    password => 'guest',
);

my $users = $backlog->getUsers(20);
ok($users);
ok( scalar( @{$users} ) > 0 );
is( $users->[ $#{$users} ]->id,   38 );
is( $users->[ $#{$users} ]->name, decode_utf8('管理者') );
