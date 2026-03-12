use strict;
use warnings;
use Test::More;
use File::Path 'remove_tree';

use Test::ValkeyServer;

eval { Test::ValkeyServer->new } or plan skip_all => 'valkey-server is required in PATH to run this test';

my $tmpdir = File::Temp->newdir;
my $server = Test::ValkeyServer->new(tmpdir => $tmpdir);
ok $server->pid, 'pid ok';

remove_tree($tmpdir);
ok ! -f $tmpdir;

$server->stop;
pass 'valkey exit ok';

done_testing;
