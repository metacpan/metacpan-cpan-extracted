#
#===============================================================================
#
#         FILE:  fqdn.t
#
#  DESCRIPTION:  Test hostname accessor
#
#===============================================================================

use strict;
use warnings;

use Test::More tests => 6;                      # last test to print

use BBPerl;
use Net::Domain qw(hostname hostfqdn);

$ENV{BBHOME}="/tmp";
$ENV{BBTMP}="/tmp";

my $bb = new BBPerl;

# Test deprecated interface
can_ok($bb, 'useFQDN');
is($bb->hostname, hostname, 'default hostname() is the local hostname');
$bb->useFQDN(1);
is($bb->hostname, hostfqdn, 'Host now using FQDN');
is($bb->useFQDN, 1, 'useFQDN is properly set');
$bb->hostname('abcdef');
is($bb->hostname, 'abcdef', 'hostname(\'value\') properly sets the hostname');
is($bb->useFQDN, 0, 'useFQDN is properly set');
