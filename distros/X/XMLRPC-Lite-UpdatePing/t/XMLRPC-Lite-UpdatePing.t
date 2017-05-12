use strict;
use Test::More qw(no_plan);

BEGIN { use_ok 'XMLRPC::Lite::UpdatePing'; };

my $client = XMLRPC::Lite::UpdatePing->new;
ok $client, 'new';

my $ping_servers = [ 'http://api.my.yahoo.com/RPC2',
                     'http://rpc.reader.livedoor.com/ping', ];
my $res;

ok $res = $client->add_ping_server('http://api.my.yahoo.com/RPC2'), '$obj->add_ping_server($uri);';
is $res, $client, 'returns $self';
my $count = @{$client->ping_servers};
is $count, 4, 'result';

ok $res = $client->setup_ping_servers($ping_servers), '$obj->setup_ping_servers($uri_array_ref);';
is $res, $client, 'returns $self';
$count = @{$client->ping_servers};
is $count, 2, 'result';

my $feed = { 'the radius of 5 meters' => 'http://seratch.blogspot.com/feeds/posts/default' };
ok $client->ping($feed), '$obj->ping($feed_hash_ref);';

__END__
