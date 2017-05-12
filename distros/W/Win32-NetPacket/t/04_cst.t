#!/usr/bin/perl -w
#
# Test methods
#

use strict;
use Test::More;

use Win32::NetPacket qw/ :oid :ndis /;

my %OIDTAG;

my $count=0;
foreach my $name (qw/ ndis oid /) {
  $count += @{$Win32::NetPacket::EXPORT_TAGS{$name}};
}

plan tests => 428;

ok( $count == 427);

foreach my $name (qw/ ndis oid  /) {
  foreach my $tag (@{$Win32::NetPacket::EXPORT_TAGS{$name}}) {
    my $hexa = scalar Win32::NetPacket::constant($tag);
      ok( $hexa !~ /Your vendor/ );
  }
}