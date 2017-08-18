use strict;
use warnings;

use Test::More tests => 3;
use URI;

my $uri = URI->new('tcp://host:1234');
is($uri->host, 'host', 'host');
is($uri->port, 1234, 'port');
is($uri->protocol, 'tcp', 'protocol');
