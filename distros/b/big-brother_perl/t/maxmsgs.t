#
#===============================================================================
#
#         FILE:  maxmsgs.t
#
#  DESCRIPTION:  Test maximum message limit
#
#===============================================================================

use strict;
use warnings;

use Test::More tests => 80;                      # last test to print

use BBPerl;
use Net::Domain qw(hostname hostfqdn);

$ENV{BBHOME}="/tmp";
$ENV{BBTMP}="/tmp";

my $bb = new BBPerl;

# Test deprecated interface
can_ok($bb, qw(addMsg getMsgCount));
for (my $i=1;$i<=75;$i++) {
	$bb->addMsg($i);
	is($bb->getMsgCount,$i,'Message count is correct');
}
$bb->addMsg("this");
is($bb->getMsgCount,75,'Message limit is not exceeded');
$bb->addMsg("that");
is($bb->getMsgCount,75,'Message limit is not exceeded');
is(grep(/this/,$bb->addMsg()),0,'Message limit successfully preserved');
is(grep(/that/,$bb->addMsg()),0,'Message limit successfully preserved');
