use lib 't/lib';

use Test::More;

use strict;
use warnings;

plan tests => 3;

use_ok ('Test::XML::RPC::Catalyst','Catty');

my $xmlrpc = Test::XML::RPC::Catalyst->new;

$xmlrpc->can_xmlrpc_methods ([qw/foo/]);

is ($xmlrpc->call ('foo',42),42);

