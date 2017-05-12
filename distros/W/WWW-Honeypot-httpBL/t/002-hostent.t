use strict;
use warnings;
use Test::More;

use Net::hostent;
use Socket;

plan tests => 2;

my $host = 'cpan.org';
my $resp = gethost($host);

ok( defined $resp, ' got response from hostent()' );
like( inet_ntoa($resp->addr), 
      '/^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/',
      ' and it looks like an IP address');

