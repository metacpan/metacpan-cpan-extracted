use strict;
use warnings;

use URI;
use Test::More tests => 11;

my $uri = URI->new('fasp://example.com');
isa_ok($uri, 'URI::fasp');
is($uri->port, 22);
is($uri->default_fasp_port, 33001);
is($uri->fasp_port, 33001);
is("$uri", 'fasp://example.com');

# Like other URI subclasses the port should only be shown if it's explicitly set
$uri->fasp_port(33001);
is("$uri", 'fasp://example.com?port=33001');

$uri = URI->new('fasp://example.com:33001?port=5000&bwcap=1000&policy=fair&httpport=8080&targetrate=50000');
is($uri->fasp_port, 5000);
$uri->fasp_port(33001);
is($uri->fasp_port, 33001);

my $ssh = $uri->as_ssh;
isa_ok($ssh, 'URI::ssh');
is($ssh->port, 33001);
is($ssh->query, undef);



