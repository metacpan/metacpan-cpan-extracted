#!/usr/bin/perl -w
#
# Test methods
#

use strict;
use Test::More;

plan tests => 16;

use Win32::NetPacket qw/ :oid :ndis GetAdapterNames GetNetInfo /;

# adapters list ----- 1
my @adapt = GetAdapterNames();
ok(@adapt);

# default adapter ----- 2
my $adapt = GetAdapterNames();
ok($adapt);

# GetNetInfo ----- 3
my @r = GetNetInfo( $adapt );
ok( 2 == @r );

# open adapter #1 ----- 4
{
  my $nic = Win32::NetPacket->new(
      adapter_name => $adapt,
      driver_buff_size => 128*1024,
      read_timeout => 1000,
      min_to_copy => 4*1024,
      mode => 0
  );
  ok($nic);
}

# open adapter #2 ----- 5
my $nic = Win32::NetPacket->new();
ok($nic);

# GetRequest vendor description ----- 6
my $Oid = pack "LLC256", OID_GEN_VENDOR_DESCRIPTION, 256;
ok( $nic->GetRequest($Oid) );

# SetRequest promiscuous mode ----- 7
$Oid = pack "LLL", OID_GEN_CURRENT_PACKET_FILTER , NDIS_PACKET_TYPE_PROMISCUOUS ;
ok( $nic->SetRequest($Oid) );

# mode NDIS_PACKET_TYPE_PROMISCUOUS ----- 8
ok($nic->SetHwFilter(NDIS_PACKET_TYPE_PROMISCUOUS));

# set a 512K buffer in the driver ----- 9
ok($nic->SetDriverBufferSize( 512*1024 ));

# set a 1 second read timeout ----- 10
ok($nic->SetReadTimeout( 1000 ));

# set the user's buffer ----- 11
my $Buff;
$nic->SetUserBuffer($Buff, 128*1024);
ok(1);

# capture the packets ----- 12
ok(defined $nic->ReceivePacket());

# Associate a BPF filter to the adapter (1) ----- 13

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

ok($nic->SetBpf($filter));

# Associate a BPF filter to the adapter (2) ----- 14

my @filter = qw/
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

ok($nic->SetBpf(@filter));

# Associate a BPF filter to the adapter (3) ----- 15

@filter = qw/
11
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

ok($nic->SetBpf(@filter));

# GetInfo ----- 16

my @info = $nic->GetInfo();
ok(@info == 7);
