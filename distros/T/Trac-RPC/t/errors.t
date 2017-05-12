use RPC::XML::Server;
use RPC::XML::Client;
require "t/utils.pl";

use Test::More tests => 2;

use Trac::RPC;

my $port;
unless ($port = &find_port) {
    die "No usable port found between 9000 and 10000, skipping"
}

my $params = {
    realm => "Bessarabov's Trac Server",
    user => "rpc",
    password => "password",
    host => "http://localhost:$port",
};

my $tr = Trac::RPC->new($params);

# Exception TracExceptionConnectionRefused
# (there is no web sever on specified address)
{
    my $page;
    eval {
        $page = $tr->get_page('WikiStart');
    };

    ok(Exception::Class->caught('TracExceptionConnectionRefused'), 'Caught TracExceptionConnectionRefused');
}

my $server = RPC::XML::Server->new(host => 'localhost', port => $port);
die "Failed to create server: $server, stopped" unless (ref $server);
my $child = start_server($server);

# TracExceptionUnknownMethod
# (there is xmlrpc server, but there is no needed method)
{
    my $page;
    eval {
        my $page = $tr->get_page('WikiStart');
    };
    ok(Exception::Class->caught('TracExceptionUnknownMethod'), 'Caught TracExceptionUnknownMethod');
}

stop_server($child);
