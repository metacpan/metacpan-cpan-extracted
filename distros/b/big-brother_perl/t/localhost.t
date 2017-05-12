#
#===============================================================================
#
#         FILE:  hostname.t
#
#  DESCRIPTION:  Test localhost accessor
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
can_ok($bb, 'localhost');
is($bb->localhost, hostname, 'default localhost() is the local hostname');
$bb->localhost('abcdef');
is($bb->localhost, 'abcdef', 'localhost(\'value\') properly sets the hostname');


