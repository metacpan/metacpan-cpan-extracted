use strict;
use warnings;
use Test::More;

use Test::RedisServer;

local $ENV{PATH} = '';

my $server;
eval {
    $server = Test::RedisServer->new;
};
ok !$server, 'server was not created ok';
like $@, qr/^exec failed: no such file or directory/m, 'error msg ok';

done_testing;
