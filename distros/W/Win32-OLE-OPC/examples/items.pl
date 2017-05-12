#!d:/win32apps/perl/bin/perl.exe -w

# Copyright (c) 1999-2001 by Martin Tomes. All rights reserved.
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

# Put the path to your perl interpreter above if you are using bash as your
# shell.

# $Id: items.pl,v 1.2 2001/01/11 10:40:40 martinto Exp $

# This example lists all the items in the server address space listing all the
# properties of that item.  It uses the OPC browser methods to do this.

# It is assumed that you are using the FactorySoft OPC automation DLL which
# has the progid 'OPC.Automation'.

use strict;
use Win32::OLE::OPC qw(GetOPCServers);

my $opcintf;

sub ShowThisLevel {
  # Shows this level of the hierarchy and recurse into each branch.
  my ($path) = @_;              # The path to this level.

  $path .= '.' if (length($path)); # Put a . separator in if not the root.

  foreach my $item ($opcintf->Leafs) {
    my %result = $opcintf->ItemData($item->{itemid});
    print $path, $item->{name}, "\n";
    for my $attrib (keys %result) {
      print "        '", $attrib, "' = '", $result{$attrib}, "'", "\n";
    }
    print "\n";
  }

  foreach my $item ($opcintf->Branches) {
    $opcintf->MoveDown($item->{name});
    &ShowThisLevel($path . $item->{name});
    $opcintf->MoveUp;
  }
}

my @available_servers = GetOPCServers('OPC.Automation');

foreach my $server (@available_servers) {
  # Connect to this server.

  $opcintf = Win32::OLE::OPC->new('OPC.Automation', $server)
    or die "Failed to connect to $server: @!";

  # List it from the top.
  &ShowThisLevel('');
}


