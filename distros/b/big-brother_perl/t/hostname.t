#
#===============================================================================
#
#         FILE:  hostname.t
#
#  DESCRIPTION:  Test hostname accessor
#
#===============================================================================

use strict;
use warnings;

use Test::More tests => 3;                      # last test to print

use BBPerl;
use Net::Domain qw(hostname);

$ENV{BBHOME}="/tmp";
$ENV{BBTMP}="/tmp";

my $bb = new BBPerl;

# Test deprecated interface
can_ok($bb, 'hostname');
is($bb->hostname, hostname, 'default hostname() is the local hostname');
$bb->hostname('abcdef');
is($bb->hostname, 'abcdef', 'hostname(\'value\') properly sets the hostname');


