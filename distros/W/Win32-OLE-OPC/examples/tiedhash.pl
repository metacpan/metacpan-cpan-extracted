#!d:/win32apps/perl/bin/perl.exe -w

# Copyright (c) 1999-2001 by Martin Tomes. All rights reserved.
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

# Put the path to your perl interpreter above if you are using bash as your
# shell.

# $Id: tiedhash.pl,v 1.2 2001/01/11 10:40:40 martinto Exp $

# This example lists all the items in the server address space listing all the
# properties of that item.  It uses a tied hash to do this.  This method of
# accessing the server is very convenient but not terribly efficient.

# It is assumed that you are using the FactorySoft OPC automation DLL which
# has the progid 'OPC.Automation'.

use strict;
use Win32::OLE::OPC qw(GetOPCServers);

my @available_servers = GetOPCServers('OPC.Automation');

foreach my $server (@available_servers) {
  # Connect to this server.

  my %OPC;
  tie %OPC, 'Win32::OLE::OPC', 'OPC.Automation', $server
    or die "Failed to connect to $server: @!";

  # OK connected, now list the items and their properties...
  for my $key (keys %OPC) {
    my %x = %{$OPC{$key}};
    print $key, "\n";
    for my $attrib (keys %x) {
      print "        '", $attrib, "' = '", $x{$attrib}, "'", "\n";
    }
    print "\n";
  }
}
