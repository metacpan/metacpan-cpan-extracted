use strict;
use warnings;
use Test::More;

use Test::ValkeyServer;

local $ENV{PATH} = '';

my $server;
eval {
    $server = Test::ValkeyServer->new;
};
ok !$server, 'server was not created ok';
like $@, qr/^exec failed: no such file or directory/m, 'error msg ok';

done_testing;
