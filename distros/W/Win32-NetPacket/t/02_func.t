#!/usr/bin/perl -w
#
# Test functions
#

use strict;
use Test::More;

plan tests => 14;

use Win32::NetPacket;

# adapters list ----- 1
my @adapt = Win32::NetPacket::GetAdapterNames();
ok(@adapt);

# open adapter ----- 2
my $adapt = Win32::NetPacket::_PacketOpenAdapter($adapt[0]);
ok($adapt);

# mode NDIS_PACKET_TYPE_PROMISCUOUS ----- 3
ok(Win32::NetPacket::_PacketSetHwFilter($adapt,0x0020));

# set a 512K buffer in the driver ----- 4
ok(Win32::NetPacket::_PacketSetBuff($adapt, 512000));

# set a 1 second read timeout ----- 5
ok(Win32::NetPacket::_PacketSetReadTimeout($adapt,1000));

# allocate a packet structure ----- 6
my $packet = Win32::NetPacket::_PacketAllocatePacket();
ok($packet);

# and initialize this packet structure ----- 7
my $Buff = ' 'x (128*1024);
Win32::NetPacket::_PacketInitPacket($packet, $Buff);
ok(1);

# capture the packets ----- 8
ok(defined Win32::NetPacket::_PacketReceivePacket($adapt,$packet));

# PacketGetRequest vendor description ----- 9
my $Oid = pack "LLC1024", 0x0001010D, 1024; # OID_GEN_VENDOR_DESCRIPTION
ok(Win32::NetPacket::_PacketGetRequest($adapt, $Oid));

# Associate a BPF filter to the adapter ----- 10

my $filter = pack 'SCCi'x11, qw/
40 0 0 12
21 0 8 2048
48 0 0 23
21 0 6 6
40 0 0 20
69 4 0 8191
177 0 0 14
80 0 0 27
69 0 1 3
6 0 0 96
6 0 0 0
/;

ok(Win32::NetPacket::_PacketSetBpf($adapt, $filter));

# close packet ----- 11 - 12
Win32::NetPacket::_PacketFreePacket($packet);
ok($packet == 0);
Win32::NetPacket::_PacketFreePacket($packet);
ok(1); # no crash ...

# close adapter ----- 13 - 14
Win32::NetPacket::_PacketCloseAdapter($adapt);
ok($adapt == 0);
Win32::NetPacket::_PacketCloseAdapter($adapt);
ok(1); # no crash ...
