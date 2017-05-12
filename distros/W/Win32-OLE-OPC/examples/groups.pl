#!d:/win32apps/perl/bin/perl.exe -w

# Copyright (c) 1999-2001 by Martin Tomes. All rights reserved.
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

# Put the path to your perl interpreter above if you are using bash as your
# shell.

# $Id: groups.pl,v 1.3 2001/01/11 10:40:40 martinto Exp $

# This example uses groups, group, items and item objects to get and set data
# from the server.  You will have to supply the OPC path names of some items
# and the server they are in for this to do anything.

# It is assumed that you are using the FactorySoft OPC automation DLL which
# has the progid 'OPC.Automation'.

use strict;
use Win32::OLE::OPC qw(GetOPCServers $OPCCache $OPCDevice);
use Sys::Hostname;

my $server;
my @items_read;
my %items_write;
if (hostname =~ /eurotherm.co.uk$/) {
  $server = 'Eurotherm.ModbusServer.1';
  @items_read = ('COM2._Diagnostics.Port Information.Characters Sent',
                 'COM2._Diagnostics.Port Information.Characters Received',
                 'COM2._Diagnostics.Port Information.Baud Rate',
                 'COM2._Diagnostics.Port Information.Data Bits');
  %items_write = ('COM2.ID002-2604-V104.INSTRUMENT.Options.Loops' => 1);
} else {
  # Put your values in here.
}

die "No server specified" unless ($server);
die "No read items specified" unless (@items_read);
die "No write items specified" unless (%items_write);

my @available_servers = GetOPCServers('OPC.Automation');
my $found_server = 0;
for my $name (@available_servers) {
  $found_server = 1 if (lc($name) eq lc($server));
}
unless ($found_server) {
  print "Cannot find server $server, valid choices are: ";
  print join " ", @available_servers;
  print "\n";
  exit 1;
}

# Connect to the selected server.
my $opcintf = Win32::OLE::OPC->new('OPC.Automation', $server)
  or die "Failed to connect to $server: @!";

# Map the names given in items_read and items_write to item id's.
foreach my $name (@items_read) {
  # Perl sets $name to be a reference to the element in @items_read so you can
  # modify it like this.
  $name = $opcintf->GetItemIdFromName($name);
}

my %new_write;
foreach my $key (keys %items_write) {
  my $itemid = $opcintf->GetItemIdFromName($key);
  $new_write{$itemid} = $items_write{$key};
}
undef %items_write;
%items_write = %new_write;
undef %new_write;

# Fetch the OPCGroups collection as an object.  The object returned is a
# reference to a hash blessed into the Win32::OLE::OPC::Groups class.
my $groups = $opcintf->OPCGroups;

# Add an anonymous group.  You can pass a string parameter to
# Win32::OLE::OPC::Groups::Add(), in which case the new group takes on the
# name passed in.  This returns a reference to a hash blessed into the
# Win32::OLE::OPC::Group class.
my $groupanon = $groups->Add();

# Get the items collection from the group object.  This returns a reference to
# a hash blessed into the Win32::OLE::OPC::Items class.
my $items = $groupanon->OPCItems;

# Each item has an id which is assigned by the client.  Generate an id for
# each item in @items_read.
my @itemids;
my $counter=0;
for my $item (@items_read) {
  push @itemids, $counter++;
}

# This adds all the items in one call.
$items->AddItems($#items_read+1, [@items_read], [@itemids]);

# Now add the items to write.
my $groupwrite = $groups->Add('write');
my $witems = $groupwrite->OPCItems;
for my $item (keys(%items_write)) {
  $witems->AddItem($item, $counter++);
}

# Now show the properties of each of the above objects.
sub PrintProperties {
  my $properties = shift;       # Takes a reference to the properties.

  # Loop through the keys.
  for my $prop (keys %$properties) {
    if (defined($properties->{$prop})) {
      printf "%24s: %s\n", $prop,  $properties->{$prop};
    } else {
      printf "%24s: Undefined\n", $prop;
    }
  }
}

my %props;

%props = $groups->Properties;
print "OPCGroups Properties\n=================\n";
PrintProperties(\%props);
print "\n";

%props = $groupanon->Properties;
print "OPCGroup Properties\n=================\n";
PrintProperties(\%props);
print "\n";

%props = $items->Properties;
print "OPCItems (read) Properties\n=================\n";
PrintProperties(\%props);
print "\n";

%props = $witems->Properties;
print "OPCItems (write) Properties\n=================\n";
PrintProperties(\%props);
print "\n";

# Now print out the item properties and values for the anonymous group.
for (my $i = 1; $i <= ($#items_read+1); $i++) {
  my $item = $items->Item($i);
  if (defined($item)) {
    %props = $item->Properties;
    print "OPCItem Properties\n=================\n";
    PrintProperties(\%props);
    print "OPCItem Data\n=================\n";
    PrintProperties($item->Read($OPCDevice)); # Reads from the device.
    print "\n";
  }
}

# Now read, write and re-read these.
$counter = 1;
for my $item_name (keys(%items_write)) {
  my $item = $witems->Item($counter++); # Assume they are in order!
  if (defined($item)) {
    # Read everything.
    %props = $item->Properties;
    print "OPCItem Properties\n=================\n";
    PrintProperties(\%props);
    print "OPCItem Data\n=================\n";
    PrintProperties($item->Read($OPCDevice)); # Reads from the device.
    my $curval = $item->Read($OPCCache)->{'Value'};
    $item->Write($items_write{$item_name});
    sleep(2);
    my $newval = $item->Read($OPCDevice)->{'Value'};
    printf "%24s: %s\n", 'New Value',  $newval;
    $item->Write($curval);
    $newval = $item->Read($OPCDevice)->{'Value'};
    printf "%24s: %s\n", 'Set back to',  $newval;
  }
}

# Now get the server handle for each item and remove it from the items list.
my @server_handles;
for (my $i = 1; $i <= ($#items_read+1); $i++) {
  my $item = $items->Item($i);
  if (defined($item)) {
    push @server_handles, $item->ServerHandle;
  }
}
$counter = 1;
for my $item_name (keys(%items_write)) {
  my $item = $witems->Item($counter++); # Assume they are in order!
  if (defined($item)) {
    push @server_handles, $item->ServerHandle;
  }
}
$items->Remove(\@server_handles);
