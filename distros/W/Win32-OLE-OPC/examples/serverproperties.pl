#!d:/win32apps/perl/bin/perl.exe -w

# Copyright (c) 1999-2001 by Martin Tomes. All rights reserved.
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

# Put the path to your perl interpreter above if you are using bash as your
# shell.

# $Id: serverproperties.pl,v 1.2 2001/01/11 10:40:40 martinto Exp $

# This example shows the properties of all the installed servers.

# It is assumed that you are using the FactorySoft OPC automation DLL which
# has the progid 'OPC.Automation'.

use strict;
use Win32::OLE::OPC qw(GetOPCServers);

my @available_servers = GetOPCServers('OPC.Automation');

sub PrintServerProperties {
  my $properties = shift;       # Takes a reference to the properties.

  # Loop through the keys.  There are a couple of specials, OPCGroups is a
  # hash of opc groups which have been defined.  This in turn contains a
  # Parent member which points back up and so ought to be ignored in this
  # context or one will loop forever.
  my $prop;
  for $prop (keys %$properties) {
    # Properties can have the value undef.
    unless (defined($properties->{$prop})) {
      printf "%16s: Undefined\n", $prop;
    } else {
      if ($prop eq 'OPCGroups') {
        printf "%16s:\n", $prop;
        my $x = $properties->{'OPCGroups'};
        for my $prop (keys %$x) {
          printf "%16s: %22s: %s\n", '', $prop, $x->{$prop}
            if ($prop ne 'Parent');
        }
      } else {
        printf "%16s: %s\n", $prop,  $properties->{$prop};
      }
    }
  }
}

foreach my $server (@available_servers) {
  # Connect to this server.

  my $opcintf = Win32::OLE::OPC->new('OPC.Automation', $server)
    or die "Failed to connect to $server: @!";

  my %ServerProps = $opcintf->ServerProperties;
  print "Server Properties\n=================\n";
  PrintServerProperties(\%ServerProps);
  print "\n";
}
