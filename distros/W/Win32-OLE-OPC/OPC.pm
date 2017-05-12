package Win32::OLE::OPC;

# Copyright (c) 1999-2001 by Martin Tomes. All rights reserved.
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

# $Id: OPC.pm,v 1.16 2002/04/30 09:14:55 martinto Exp $

=pod

=head1 NAME

Win32::OLE::OPC - OPC Server Interface

=head1 SYNOPSIS

Two ways of using the OPC interface are provided, the class methods:

    use Win32::OLE::OPC;

    my $opcintf = Win32::OLE::OPC->new('Someones.OPCAutomation',
                                       'Someones.Server');
    $opcintf->MoveToRoot;
    foreach $item ($opcintf->Leafs) {
      print $item->{name}, "\n";
      my %result = $opcintf->ItemData($item->{itemid});
      for $attrib (keys %result) {
        print "        [", $attrib, " = '", $result{$attrib}, "']", "\n";
      }
      print "\n";
    }
    foreach $item ($opcintf->Branches) {
      print $item->{name}, "\n";
    }

or a tied hash:

    use Win32::OLE::OPC;

    my %OPC;
    tie %OPC, Win32::OLE::OPC, 'Someones.OPCAutomation', 'Someones.Server';

    # OK, list the keys...
    for $key (keys %OPC) {
      my %x = %{$OPC{$key}};
      print $key, "\n";
      for $attrib (keys %x) {
        print "        '", $attrib, "' = '", $x{$attrib}, "'", "\n";
      }
      print "\n";
    }

The tied hash method has to return a reference to a hash containing the item
data hence the unpleasant code 'C<%x = %{$OPC{$key}}>'.  Alternatively one can
assign the returned value into a scalar and dereference it when using the hash
like this 'C<keys %$x>' and 'C<$result-E<gt>{$item}>'.

Note that both methods can be used together.  First create an interface using the C<new()> method and then tie it like this:

    tie %OPC, $opcintf, 'Someones.OPCAutomation', 'Someones.Server';

To connect to a remote server add the name of the server as a parameter to the
call to new() or to the tie:

  my $opcintf = Win32::OLE::OPC->new('Someones.OPCAutomation',
                                     'Someones.Server',
                                     'machine.name');
  tie %OPC, Win32::OLE::OPC, 'Someones.OPCAutomation',
                             'Someones.Server',
                             'machine.name';

=head1 DESCRIPTION

A partial implementation of the OLE for Process Control dispatch interface as
defined in the 'Data Access Automation Interface Standard' version 2.

An exception is raised using C<Carp::croak()> on any failure.

=head2 METHODS

=over 4

=cut

use Win32::OLE qw(HRESULT);
use Win32::WinError;
use Win32::OLE::Variant;
use Sys::Hostname;
use Carp;
use strict;
use vars qw/$VERSION @ISA @EXPORT @EXPORT_OK $OPCCache $OPCDevice
  $dont_show_property_exceptions/;

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw($OPCCache $OPCDevice);
# GetOPCServers can be called without an object reference.
@EXPORT_OK = qw(&GetOPCServers $show_property_exceptions);
$VERSION = '0.92';

# Constants.
$OPCCache = 1;
$OPCDevice = 2;
# Turn on some more error reporting.
$dont_show_property_exceptions = 1;

my $quiet = 1;
my $DEBUG = 0;

BEGIN {
  Win32::OLE->Option(Warn => 0); # Ignore errors and return undef.
}

# Here for convenience, returns the name of the function which called the
# current function, is used for reporting errors.
sub _whowasi { (caller(1))[3] . '()' }

sub _check_error {
  # Check the HRESULT which came back from the dll.
  my $msg = shift;                 # A message to print with the error.
  my $quiet = shift;

  if (Win32::OLE->LastError() != S_OK) {
    carp "$msg:\n    " . Win32::OLE->LastError() . "\n" unless ($quiet);
    return 1;                   # Was bad.
  }
  return 0;                     # Was OK.
}

=pod

=item Win32::OLE::OPC->new(DLLPROGID, SERVERPROGID, SERVERNODE)

The C<new()> method creates an instance of an OPC server object.  The
C<DLLPROGID> argument is the COM progid of the Dll which implements the Dispatch
interface to the OPC server.  The C<SERVERPROGID> is the COM progid of the OPC
server containing the data you wish to access.  The DLLPROGID and SERVERPROGID
arguments are required.

The SERVERNODE argument is optional and is the name of a remote machine
running the SERVERPROGID.  When SERVERNODE is specified a connection is made
to the server using DCOM.  WARNING: DCOM security can be a little difficult to
understand so perseverance is required.

As the OPC specification only allows one browser per instance of the dispatch
Dll the C<new()> method creates and keeps a browser object in
C<Win32::OLE::OPC-E<gt>{browser}>

=cut

sub new {
  my $that = shift;             # Either a class name or a reference to one.
  my $class = ref($that) || $that; # Allow class name or reference to work.
  my $opcdllprogid = shift;     # The OPC foundation dispatch interface DLL.
                                # Each vendor will have their own ProgID etc.
  my $serverprogid = shift;     # The server to connect to.
  my $servernode = shift;       # The machine the server is running on.

  croak "usage: @{[&_whowasi]} DLLPROGID SERVERPROGID" if @_;

  # Save the progid's as they might be useful.
  my $self = {
    _opcdllprogid => $opcdllprogid,
    _serverprogid => $serverprogid
    };
  # Get an instance of the OPC dispatch DLL.
  $self->{dllintf} = Win32::OLE->new($opcdllprogid)
    or croak "Failed to connect to dispatch DLL $opcdllprogid";
  # Connect to the selected server.
  if ($servernode) {
    $self->{dllintf}->Connect($serverprogid, $servernode);
  } else {
    $self->{dllintf}->Connect($serverprogid);
  }
  &_check_error("OPC::Connect to server " . $serverprogid);
  # Register my name on the server.
  $self->{dllintf}->{ClientName} = $0 . " on " . hostname;
  &_check_error("OPC::Connect to server - add client name " . $serverprogid);
  # One can only have one browser so make it internal and create it now.
  $self->{browser} = $self->{dllintf}->CreateBrowser
    || croak "Failed to create browser for " . $serverprogid;
  bless $self, $class;
  return $self;
}

# -----------------------------------------------------------------------------
# Browser methods.
#
# These sort of mirrors the browser interface but it appears on the
# Win32::OLE::OPC object.  The rational behind this is that an instance of the
# DLL can only provide one browser anyway so why not hide a level of
# complexity and put it up into the main object.  The main difference is that
# the collections are turned into arrays which are both stored in the object
# hash and returned.
# -----------------------------------------------------------------------------

=pod

=item MoveToRoot

A browser method.  Moves the current browse position to the root of the
address space.

=cut

sub MoveToRoot {
  my $self = shift;
  $self->{browser}->MoveToRoot();
  &_check_error("OPC::MoveToRoot " . $self->{_serverprogid});
}

=pod

=item MoveDown(TO)

A browser method.  Moves the current browse position one branch down the
address space.  The C<TO> parameter is the branch name.

=cut

sub MoveDown {
  my $self = shift;
  my $to = shift;               # Name of the branch to move to relative to
                                # the current branch.
  $self->{browser}->MoveDown($to);
  &_check_error("OPC::MoveDown " . $self->{_serverprogid}, $quiet);
}

=pod

=item MoveUp

A browser method.  Moves the current browse position one node up the address
space.

=cut

sub MoveUp {
  my $self = shift;
  $self->{browser}->MoveUp();
  &_check_error("OPC::MoveUp " . $self->{_serverprogid}, $quiet);
}

=pod

=item MoveTo(TO)

A browser method.  Moves the current browse position to the absolute location
specified by C<TO>.

    $opcintf->MoveTo('COM1._Diagnostics');

=cut

sub MoveTo {
  my $self = shift;
  my $to = shift;
  my @to = split /\./, $to;     # Turn it into an array.

  $self->MoveToRoot;            # Always start at the top.
  foreach my $branch (@to) {
    $self->MoveDown($branch);
    &_check_error("OPC::MoveTo/MoveDown " . $self->{_serverprogid}, $quiet);
  }
}

# I can't get an array of BSTR to work :-(
#sub MoveTo {
#  my $self = shift;
#  my $to = shift;               # name of the branch to move to relative to
#                                # the root.
#  my @to = split /\./, $to;     # Turn it into an array.
#  my $vto = Variant(VT_ARRAY|VT_BSTR, [0, $#to]);
#  print '$#to = ', $#to, "\n";
#  for (my $i=0; $i<=$#to; $i++) {
#    $vto->Put($i, $to[$i]);
#  }
#  $self->{browser}->MoveTo($vto);
#  &_check_error("OPC::MoveTo " . $self->{_serverprogid});
#}

# I can't get a ref to an array to work either!
#sub MoveTo {
#  my $self = shift;
#  my $to = shift;
##  my @to = split /\./, $to;     # Turn it into an array.
#  my $to2 = [ split /\./, $to ];     # Turn it into an array ref.
#
#  $self->{browser}->MoveTo($to2);
#
#  &_check_error("OPC::MoveTo " . $self->{_serverprogid});
#}

=pod

=item Branches

A browser method.

Returns the branch names and itemid in a hash in an array.  The method has a
different name from the OPC ShowBranches method because it doesn't do quite
the same thing.

The returned array is also stored in C<Win32::OLE::OPC-E<gt>{items}>.

See synopsis for an example of how to call this method.

=cut

#'  Satisfy emacs syntax colouring:-(

sub Branches {
  my $self = shift;
  $self->{browser}->ShowBranches(); # Fill the collection in the Dll.
  &_check_error("OPC::Branches " . $self->{_serverprogid});
  @{$self->{items}} = ();       # Clear out the items array.
  foreach my $item (in {$self->{browser}}) {
    push @{$self->{items}}, { name => $item,
                              itemid => $self->{browser}->GetItemID($item),
                            };
  }
  # Set the count property.
  $self->{count} = $self->{browser}->{Count};
  return @{$self->{items}};     # Return the list of items.
}

=pod

=item Leafs

A browser method.

Returns the leaf names and itemid in a hash in an array.  The method has a
different name from the OPC ShowLeafs because it doesn't do quite the same
thing.  The hash has the members C<name> and C<itemid>.  The number of items
in the array is saved in C<Win32::OLE::OPC-E<gt>{count}>

The returned array is also stored in C<Win32::OLE::OPC-E<gt>{items}>.

    foreach $item ($opcintf->Leafs) {
      print $item->{name}, " ", item->{itemid}, "\n";
    }

=cut

#'  Satisfy emacs syntax colouring:-(

sub Leafs {
  my $self = shift;
  my $flat = shift;             # Whether to flatten out the namespace.
  $flat ||= 0;                  # Set false if undefined.
  my $vflat = Variant(VT_BOOL, $flat); # Need it as a variant.
  $self->{browser}->ShowLeafs($vflat); # Fill the collection in the Dll.
  &_check_error("OPC::Leafs " . $self->{_serverprogid});
  @{$self->{items}} = ();       # Clear out the items array.
  foreach my $item (in {$self->{browser}}) {
    push @{$self->{items}}, { name => $item,
                              itemid => $self->{browser}->GetItemID($item),
                            };
    &_check_error("OPC::Leafs " . $self->{_serverprogid});
  }
  # Set the count property.
  $self->{count} = $self->{browser}->{Count};
  return @{$self->{items}};     # Return the list of items.
}

=pod

=item Item(N)

Returns a hash contining the name and itemid of item C<N>.  Calls to
C<Leafs> and C<Branches> collect the item data.  This is an alternative method
of fetching the address space.

  $opcintf->Leafs;
  for (my $i = 0; $i < $opcintf->{count}; $i++) {
    my $item = $opcintf->Item($i);
    print $item->{name}, " ", item->{itemid}, "\n";
  }

=cut

sub Item {
  my $self = shift;
  my $num = shift;              # 1 based index into last fetched browser
                                # collection.
  return ${$self->{items}}[$num - 1];
}

=pod

=item ItemData(ITEMID)

Use this to extract all the data the server holds for this item of data.  The
C<ITEMID> is the C<itemid> member of the hash returned by the C<Leafs>
method.

It returns a hash, the keys of which are the available attributes (found by
calling the OPC C<QueryAvailableProperties()> method) and the values of in the
hash are obtained by calling GetItemProperties.

=cut

sub ItemData {
  my $self = shift;             # Just *exactly* who am I?
  # Use the function which gets the reference and dereference it.  _ItemData()
  # is called here and bu FETCH().
  return %{$self->_ItemData(@_)};
}

sub _ItemData {
  my $self = shift;
  my $ItemID = shift;           # The item id was returned by Leafs.

  my $count        = Variant(VT_I4|VT_BYREF, 0);
  my $PropertyIds  = Variant(VT_ARRAY|VT_I4|VT_BYREF, []);
  my $Descriptions = Variant(VT_ARRAY|VT_BSTR|VT_BYREF, []);
  my $DataTypes    = Variant(VT_ARRAY|VT_I2|VT_BYREF, []);
  $self->{dllintf}->QueryAvailableProperties($ItemID,
                                             $count,
                                             $PropertyIds,
                                             $Descriptions,
                                             $DataTypes);
  &_check_error("OPC::QueryAvailableProperties " . $self->{_serverprogid});

  my $PropertyValues = Variant(VT_ARRAY|VT_VARIANT|VT_BYREF, [1,1]);
  my $Errors         = Variant(VT_ARRAY|VT_I4|VT_BYREF,      [1,1]);
  $self->{dllintf}->GetItemProperties($ItemID,
                                      $count, # Count
                                      $PropertyIds,
                                      $PropertyValues,
                                      $Errors);
  &_check_error("OPC::GetItemProperties " . $self->{_serverprogid});

  carp("GetItemProperties error " . $Errors->Get(1)) if ($Errors->Get(1));

  # Now turn this into a hash.
  my %result; undef %result;    # Clear it out.
  for (my $i=1; $i<=$count; $i++) {
    if ($Errors->Get($i) == HRESULT(0x80004005)) { # E_FAIL
      $result{$Descriptions->Get($i)} = undef;
    } elsif ($Errors->Get($i)) {
      croak("GetItemProperties: "
            . $self->{dllintf}->GetErrorString($Errors->Get($i))
            . " " . $Descriptions->Get($i));
    } else {
      $result{$Descriptions->Get($i)} = $PropertyValues->Get($i)
        if (defined($PropertyValues->Get($i)));
    }
  }
  return \%result;
}

sub _AvailableProperties {
  # This is an internal routine which returns the available properties for an
  # ItemID as an array of hashes.  The externally used version saves this in
  # $self->{properties}.

  my $self = shift;
  my $ItemID = shift;           # The item id was returned by Leafs.

  my $count        = Variant(VT_I4|VT_BYREF, 0);
  my $PropertyIds  = Variant(VT_ARRAY|VT_I4|VT_BYREF, []);
  my $Descriptions = Variant(VT_ARRAY|VT_BSTR|VT_BYREF, []);
  my $DataTypes    = Variant(VT_ARRAY|VT_I2|VT_BYREF, []);
  $self->{dllintf}->QueryAvailableProperties($ItemID,
                                             $count,
                                             $PropertyIds,
                                             $Descriptions,
                                             $DataTypes);
  &_check_error("OPC::QueryAvailableProperties " . $self->{_serverprogid});
  # Now turn this into an array of hashes.
  my @result = ();  # Clear it out.
  for (my $i=1; $i<=$count; $i++) {
    push @result, {
      Id => $PropertyIds->Get($i),
      Description => $Descriptions->Get($i),
      DataType => $DataTypes->Get($i)
      };
  }
  return @result;
}

=pod

=item AvailableProperties(ITEMID)

Returns the available properties of an item.  The C<ITEMID> is the C<itemid>
member of the hash returned by the C<Leafs> method.

It returns an array of hashes containing the available attributes found by
calling the OPC C<QueryAvailableProperties()> method.  The hash contains
C<Id>, C<Description> and C<DataType> members.

The returned array is also stored in C<Win32::OLE::OPC-E<gt>{properties}>.

    print " Id Type Description\n";
    foreach my $prop ($opcintf->AvailableProperties($item->{itemid})) {
      printf "%3d %4d %s\n",
          $prop->{Id},
          $prop->{DataType},
          $prop->{Description};
    }

=cut

sub AvailableProperties {
  my $self = shift;
  my $ItemID = shift;           # The item id was returned by Leafs.

  @{$self->{properties}} = $self->_AvailableProperties($ItemID);
  return @{$self->{properties}};
}

=pod

=item ServerProperties

Return a hash indexed by the following properties containing the property
value:

    StartTime CurrentTime LastUpdateTime MajorVersion
    MinorVersion BuildNumber VendorInfo ServerState LocaleID
    Bandwidth OPCGroups PublicGroupNames ServerName
    ServerNode ClientName

Note that the OPCGroups value is itself a reference to a hash and it contains
a hash member indexed 'Parent' which is a hash pointing back up.

=cut

sub ServerProperties {
  # Collect everything available into a hash and return it.
  my $self = shift;

  my %retv;                     # Return this.
  for my $property (qw/StartTime CurrentTime LastUpdateTime MajorVersion
                    MinorVersion BuildNumber VendorInfo ServerState LocaleID
                    Bandwidth OPCGroups PublicGroupNames ServerName
                    ServerNode ClientName/) {
    $retv{$property} = $self->{dllintf}->{$property};
    &Win32::OLE::OPC::_check_error("OPC::ServerProperties "
                                   . $self->{_serverprogid},
                                   $dont_show_property_exceptions);
  }
  return %retv;
}

=pod

=item GetOPCServers

Return an array containing the names of available servers.  Can be called with
the progid of the dispatch Dll as an argument, in which case it will connect
to the Dll and extract the list of servers.  It can also be called using the
object created by a call to new, in which case the name of the Dll is not
required.  The GetOPCServers is not exported by default.

  use Win32::OLE::OPC qw(GetOPCServers);

  my @AvailableServers = GetOPCServers('Someones.OPCAutomation');

=cut

sub GetOPCServers {
  my $self = shift;
  if (ref($self) eq 'Win32::OLE::OPC') {
    # Called via a blessed thingy so the dll is already connected.
    my $varray = $self->{dllintf}->GetOPCServers();
    &Win32::OLE::OPC::_check_error("OPC::GetOPCServers "
                                   . $self->{_serverprogid});
    return @$varray;
  } else {
    # Called directly, i.e., not via a blessed thingy.  Therefore I need to
    # create and then throw away an interface to the dispatch Dll.  In this
    # case $self isn't a blessed thingy reference, it is assumed to be a
    # string which should be the name of the dispatch Dll.
    my $dllintf = Win32::OLE->new($self)
      or croak "Failed to connect to dispatch DLL $self";
    my $varray = $dllintf->GetOPCServers();
    return @$varray;
  }
}

# Not implemented on any servers I have!
#sub QueryAvailableLocaleIDs {
#  my $self = shift;
#
#  ???? = $self->{dllintf}->QueryAvailableLocaleIDs;
#
#}

=pod

=item BrowserProperties

Return a hash indexed by the following properties containing the property
value:

    Organization Filter DataType AccessRights CurrentPosition Count

=cut

sub BrowserProperties {
  # Collect everything available into a hash and return it.
  my $self = shift;

  my %retv;                     # Return this.
  for my $property (qw/Organization Filter DataType AccessRights
                    CurrentPosition Count/) {
    $retv{$property} = $self->{browser}->{$property};
    &Win32::OLE::OPC::_check_error("OPC::BrowserProperties "
                                   . $self->{_serverprogid},
                                   $dont_show_property_exceptions);
  }
  return %retv;
}

=pod

=item GetItemIdFromName

This is not a standard OPC browser method.  It translates a full OPC path name
to an item id.  It is often the case that the item id and the OPC path name is
one and the same thing, but you cannot assume that!

=cut

sub GetItemIdFromName {
  my $self = shift;
  my $opc_name = shift;

  # Split it, take off the last part of the path and put it back together
  # again.  This leaves us with the branch and the item within the branch.
  my @opc_name = split /\./, $opc_name;
  my $itemname = pop @opc_name;
  $opc_name = join '.', @opc_name; # All but the last item in the path.
  # Remember where I am now.
  my $startpos = $self->{browser}->{CurrentPosition};
  $self->MoveTo($opc_name);
  my $itemid;
  foreach my $item ($self->Leafs) {
    if ($item->{name} eq $itemname) {
      $itemid = $item->{itemid};
      last;
    }
  }
  $self->MoveTo($startpos) if ($startpos); # Leave it where it was before.
  return $itemid;
}

=pod

=back

=cut


# -----------------------------------------------------------------------------
# Tied hash bit.
#
# This exposes the address space of the server as a hash whose keys are the
# browse space.
# -----------------------------------------------------------------------------

=pod

=head2 TIED HASH

See the SYNOPSIS for example code.

If you tie a hash to this module you can:

=over 4

=item Read an items attributes

A reference to a hash keyed by attribute names is returned.  See the synopsis
fo an example.

=item Access the Keys

The keys of the hash can be enumerated so C<keys> and C<each> function will
work.

=back

Writing, deleting or undefining a member of the hash is not possible.

=cut

sub TIEHASH {
  carp &_whowasi . " TIE" if ($DEBUG);
  my $that = shift;
  if (ref($that)) {
    # An existing blessed thingy has been passed in as $that.
    return $that;
  }
  my $class = $that;            # $that is the class name if we get here.
  my $opcdllprogid = shift;     # The OPC foundation dispatch interface DLL.
                                # Each vendor will have their own ProgID etc.
  my $serverprogid = shift;     # The server to connect to.
  my $servernode = shift;       # The machine the server is running on.

  # Make one and return it.
  if ($servernode) {
    return &new($class, $opcdllprogid, $serverprogid, $servernode);
  } else {
    return &new($class, $opcdllprogid, $serverprogid);
  }
}

sub FETCH {
  carp &_whowasi . " FETCH" if ($DEBUG);
  my $self = shift;
  my $path = shift;             # This is the OPC name, i need the item id.

  # Fetch the itemid for $path.

  # Split it, take off the last part of the path and put it back together
  # again.  This leaves us with the branch and the item within the branch.
  my @path = split /\./, $path;
  my $itemname = pop(@path);
  $path = join '.', @path;
  my $startpos = $self->{browser}->{CurrentPosition};
  $self->MoveTo($path);
  my $item;
  foreach $item ($self->Leafs) {
    if ($item->{name} eq $itemname) {
      # This returns a reference to a hash which works but is unpleasant to
      # use.  You need something like this...
      #
      # my $result = $OPC{'something.or.other'};
      #
      # foreach $item (keys %$result) {
      #   print "'", $item, "'", " = '", $$result{$item}, "'\n";
      # }
      #
      # or this...
      #
      # my %result = %{$OPC{'something.or.other'}};
      #
      # foreach $item (keys %result) {
      #   print "'", $item, "'", " = '", $result{$item}, "'\n";
      # }

      $self->MoveTo($startpos) if ($startpos); # Leave it where it was before.
      return $self->_ItemData($item->{itemid});
    }
  }
  $self->MoveTo($startpos) if ($startpos); # Leave it where it was before.
  return undef;                 # Failed to find it.
}

sub STORE {
  carp &_whowasi . " STORE" if ($DEBUG);
  my $self = shift;
  my $key = shift;              # This is the OPC name, i need the item id.
  my $value = shift;

  # Fetch the itemid for $key.

  # Split it, take off the last part of the path and put it back together
  # again.  This leaves us with the branch and the item within the branch.
  my @key = split /\./, $key;
  my $itemname = pop(@key);
  $key = join '.', @key;
  my $startpos = $self->{browser}->{CurrentPosition};
  $self->MoveTo($key);
  my $itemid;
  foreach my $item ($self->Leafs) {
    if ($item->{name} eq $itemname) {
      $itemid = $item->{itemid};
    }
  }

  unless (defined($itemid)) {
    carp &_whowasi . " STORE: $key.$itemname not found.";
    return undef;
  }

  unless (defined $self->{tieitems}) {
    # Create a groups object containing a group object containing an items
    # object which can be used to add an item and write to it.  Phew.
    $self->{tiegroups} = $self->OPCGroups; # The groups collection.
    # Add a group.
    $self->{tiegroup} = $self->{tiegroups}->Add('tiegroup');
    # Get the items collection.
    $self->{tieitems} = $self->{tiegroup}->OPCItems;
  }
  # OK, one has the items collection.  Add to it.
  $self->{tieitems}->AddItem($itemid, 1);
  # I only ever have one item in this group.
  my $item = $self->{tieitems}->Item(1);
  $item->Write($value);
  $self->{tieitems}->Remove([$item->ServerHandle]);
  $self->MoveTo($startpos) if ($startpos); # Leave it where it was before.
}

sub DELETE {
  carp &_whowasi . ": One cannot delete elements of this hash";
}

sub CLEAR {
  carp &_whowasi . ": One cannot clear this hash";
}

sub EXISTS {
  carp &_whowasi . " EXISTS" if ($DEBUG);
  my $self = shift;
  my $path = shift;

  # Split it, take off the last part of the path and put it back together
  # again.  This leaves us with the branch and the item within the branch.
  my @path = split /\./, $path;
  my $itemname = pop(@path);
  $path = join '.', @path;
  my $startpos = $self->{browser}->{CurrentPosition};
  $self->MoveTo($path);
  my $item;
  foreach $item ($self->Leafs) {
    if ($item->{name} eq $itemname) {
      $self->MoveTo($startpos) if ($startpos); # Leave it where it was before.
      return 1;
    }
  }
  $self->MoveTo($startpos) if ($startpos); # Leave it where it was before.
  return 0;                     # Failed to find it.
}

sub _EnumThisLevel {
  # Enumerates this level and recurse into each branch. Pushes all the item
  # names into the array referenced by $self->{_keys}
  my $self = shift;
  my ($path) = @_;              # The path to this level.

  $path .= '.' if (length($path)); # Put a . separator in if not the root.
  foreach my $item ($self->Leafs) {
    push @{$self->{_keys}}, $path. $item->{name};
  }
  foreach my $item ($self->Branches) {
    $self->MoveDown($item->{name});
    $self->_EnumThisLevel($path . $item->{name});
    $self->MoveUp;
  }
}

sub FIRSTKEY {
  carp &_whowasi . " FIRSTKEY" if ($DEBUG);
  my $self = shift;

  my $startpos = $self->{browser}->{CurrentPosition};
  $self->MoveToRoot;            # Reset to start.
  # Now read all the item names into an internal hash which will then be used
  # to return all the results.  This is far simpler than doing it on the fly
  # but does mean that it will take a while for the first value to be
  # returned.  If the array is already defined then use it unless someone sets
  # CLOBBER in the object.
  if (!defined($self->{_keys}) || $self->{CLOBBER}) {
    $self->{_keys} = ();        # Initialise the keys.
    $self->_EnumThisLevel('');
  }
  $self->{_keyidx} = 0;         # Go to the start of the array.
  $self->MoveTo($startpos) if ($startpos); # Leave it where it was before.
  return $self->NEXTKEY;        # Simplest way out!  Doesn't need lastkey arg.
}

sub NEXTKEY {
  carp &_whowasi . " NEXTKEY" if ($DEBUG);
  my $self = shift;

  if ($self->{_keyidx} <= $#{$self->{_keys}}) {
    my $result = ${$self->{_keys}}[$self->{_keyidx}];
    $self->{_keyidx}++;
    return $result;
  } else {
    return undef;
  }
}

sub DESTROY {
  carp &_whowasi . " DESTROY" if ($DEBUG);
  # No need to do anything in here.
}

=pod

=head2 OPCGroups

The Win32::OLE::OPC::OPCGroups method returns an OPCGroups object which is
blessed into the perl Win32::OLE::OPC::Groups class.

=over 4

=cut

sub OPCGroups {
  my $self = shift;
  my $groups = { _parent => $self };
  $groups->{groups} = $self->{dllintf}->{OPCGroups};
  $groups->{_serverprogid} = $self->{_serverprogid};
  &Win32::OLE::OPC::_check_error("OPC::OPCGroups "
                                 . $self->{_serverprogid});
  return bless $groups, 'Win32::OLE::OPC::Groups';
}

package Win32::OLE::OPC::Groups;
use Carp;

# -----------------------------------------------------------------------------
# OPCGroups object.
#
# Methods which can be used with the return value from OPCGroups.
#
#-----------------------------------------------------------------------------

=pod

=item Properties

Return a hash indexed by the following properties containing the property
value:

  Parent DefaultGroupIsActive DefaultGroupUpdateRate DefaultGroupDeadband
  DefaultGroupLocaleID DefaultGroupTimeBias Count

Note that the hash member indexed 'Parent' is a hash pointing back up to the
parent properties.

=cut

sub Properties {
  # Collect everything available into a hash and return it.
  my $self = shift;

  my %retv;                     # Return this.
  for my $property (qw/Parent DefaultGroupIsActive DefaultGroupUpdateRate
                    DefaultGroupDeadband DefaultGroupLocaleID
                    DefaultGroupTimeBias Count/) {
    $retv{$property} = $self->{groups}->{$property};
    &Win32::OLE::OPC::_check_error("OPC::Groups::Properties "
                                   . $self->{_serverprogid},
                             $Win32::OLE::OPC::dont_show_property_exceptions);
  }
  return %retv;
}

=item SetProperty(PROPERTY,VALUE)

Set one of these properties to the value given.

  DefaultGroupIsActive DefaultGroupUpdateRate DefaultGroupDeadband
  DefaultGroupLocaleID DefaultGroupTimeBias

=cut

sub SetProperty {
  # Collect everything available into a hash and return it.
  my $self = shift;
  my $property = shift;         # Name of the property to set.
  my $value = shift;            # The value to put in there.

  # Check the name is valid.
  my $isvalid = 0;
  for my $valid (qw/DefaultGroupIsActive DefaultGroupUpdateRate
                 DefaultGroupDeadband DefaultGroupLocaleID
                 DefaultGroupTimeBias/) {
    if ($property eq $valid) {
      $isvalid = 1;
      last;
    }
  }
  if ($isvalid) {
    $self->{groups}->{$property} = $value;
    &Win32::OLE::OPC::_check_error("OPC::Groups::SetProperty "
                                   . $self->{_serverprogid});
  } else {
    carp "Attempt to set invalid property '$property' on OPC groups";
  }
}

=pod

=item Add(NAME)

Add a group to the OPC groups collection.  NAME is optional.

=cut

sub Add {
  my $self = shift;
  my $group_name = shift;       # This is optional and therefore might be undef

  my $group = { _parent => $self };
  $group->{group} = $self->{groups}->Add($group_name);
  $group->{_serverprogid} = $self->{_serverprogid};
  &Win32::OLE::OPC::_check_error("OPC::Groups::Add "
                                 . $self->{_serverprogid});
  if (defined($group->{group})) {
    return bless $group, 'Win32::OLE::OPC::Group';
  } else {
    return undef;
  }
}

=pod

=item Item([NUMBER | NAME])

Get group by 1 based index or by the name used when it was added to the groups
list.

=cut

sub Item {
  my $self = shift;
  my $ident = shift;

  my $group = { _parent => $self };
  if ($ident =~ /^[0-9]+/) {
    # It is an integer, pass it as such.
    $group->{group} = $self->{groups}->Item(int $ident);
  } else {
    # It is a name so pass the string.
    $group->{group} = $self->{groups}->Item($ident);
  }
  $group->{_serverprogid} = $self->{_serverprogid};
  &Win32::OLE::OPC::_check_error("OPC::Groups::Item "
                                 . $self->{_serverprogid});
  if (defined($group->{group})) {
    return bless $group, 'Win32::OLE::OPC::Group';
  } else {
    return undef;
  }
}

=pod

=item GetOPCGroup([SERVERHANDLE|NAME])

Get group using the server handle or by the name used when it was added to the
groups list.

=cut

sub GetOPCGroup {
  my $self = shift;
  my $ident = shift;

  my $group = { _parent => $self };
  $group->{group} = $self->{groups}->GetOPCGroup($ident);
  $group->{_serverprogid} = $self->{_serverprogid};
  &Win32::OLE::OPC::_check_error("OPC::Groups::GetOPCGroup "
                                 . $self->{_serverprogid});
  if (defined($group->{group})) {
    return bless $group, 'Win32::OLE::OPC::Group';
  } else {
    return undef;
  }
}

=pod

=item Remove([SERVERHANDLE|NAME])

Remove group using the server handle or by the name used when it was added to
the groups list.

=cut

sub Remove {
  my $self = shift;
  my $ident = shift;

  $self->{groups}->Remove($ident);
  &Win32::OLE::OPC::_check_error("OPC::Groups::Remove "
                                 . $self->{_serverprogid});
}

=pod

=item RemoveAll

Remove all groups from the groups list.

=cut

sub RemoveAll {
  my $self = shift;

  $self->{groups}->RemoveAll;
  &Win32::OLE::OPC::_check_error("OPC::Groups::RemoveAll "
                                 . $self->{_serverprogid});
}

=pod

=item ConnectPublicGroup(NAME)

You connect to a public group, it cannot be added.  NAME is a string which
identifies the group.

This is untested as I have no server which implements public groups.

=cut

sub  ConnectPublicGroup {
  my $self = shift;
  my $group_name = shift;

  my $group = { _parent => $self };
  $group->{group} = $self->{groups}->ConnectPublicGroup($group_name);
  $group->{_serverprogid} = $self->{_serverprogid};
  &Win32::OLE::OPC::_check_error("OPC::Groups::ConnectPublicGroup "
                                 . $self->{_serverprogid});
  if (defined($group->{group})) {
    return bless $group, 'Win32::OLE::OPC::Group';
  } else {
    return undef;
  }
}

=pod

=item RemovePublicGroup([SERVERHANDLE|NAME})

You remove to a public group using this method.  NAME is a string which
identifies the group or SERVERHANDLE is the server handle.  Talk about stating
the obvious!

This is untested as I have no server which implements public groups.

=cut

sub  RemovePublicGroup {
  my $self = shift;
  my $ident = shift;

  $self->{groups}->RemovePublicGroup($ident);
  &Win32::OLE::OPC::_check_error("OPC::Groups::RemovePublicGroup "
                                 . $self->{_serverprogid});
}

=pod

=back

=cut

package Win32::OLE::OPC::Group;
use Carp;

# -----------------------------------------------------------------------------
# OPCGroup object.
#
#-----------------------------------------------------------------------------

=pod

=head2 OPCGroup

The Win32::OLE::OPC::Group object has methods Add, Item, GetOPCGroup and
ConnectPublicGroup which all return a hash blessed into the OPCGroup class.

=over 4

=item Properties

Return a hash indexed by the following properties containing the property
value:

  Parent Name IsPublic IsActive IsSubscribed ClientHandle ServerHandle
  LocaleID TimeBias DeadBand UpdateRate OPCItems

Note that the hash member indexed 'Parent' is a hash pointing back up to the
parent properties.

=cut

sub Properties {
  # Collect everything available into a hash and return it.
  my $self = shift;

  my %retv;                     # Return this.
  for my $property (qw/Parent Name IsPublic IsActive IsSubscribed ClientHandle
                    ServerHandle LocaleID TimeBias DeadBand UpdateRate
                    OPCItems/) {
    $retv{$property} = $self->{group}->{$property};
    &Win32::OLE::OPC::_check_error("OPC::Group::Properties "
                                   . $self->{_serverprogid},
                             $Win32::OLE::OPC::dont_show_property_exceptions);
  }
  return %retv;
}

=pod

=item SetProperty(PROPERTY,VALUE)

Set one of these properties to the value given.

  Name IsActive IsSubscribed ClientHandle LocaleID TimeBias DeadBand
  UpdateRate

=cut

sub SetProperty {
  # Collect everything available into a hash and return it.
  my $self = shift;
  my $property = shift;         # Name of the property to set.
  my $value = shift;            # The value to put in there.

  # Check the name is valid.
  my $isvalid = 0;
  for my $valid (qw/Name IsActive IsSubscribed ClientHandle LocaleID TimeBias
                 DeadBand UpdateRate/) {
    if ($property eq $valid) {
      $isvalid = 1;
      last;
    }
  }
  if ($isvalid) {
    $self->{group}->{$property} = $value;
    &Win32::OLE::OPC::_check_error("OPC::Group::SetProperty "
                                   . $self->{_serverprogid});
  } else {
    carp
      "Attempt to set invalid property '$property' on OPC group "
        . $self->{group}->{Name};
  }
}

=pod

=item OPCItems

The Win32::OLE::OPC::OPCGroup::OPCItems method returns an OPCItems object
which is blessed into the perl Win32::OLE::OPC::Items class.

=cut

sub OPCItems {
  my $self = shift;
  my $items = { _parent => $self };
  $items->{items} = $self->{group}->{OPCItems};
  $items->{_serverprogid} = $self->{_serverprogid};
  &Win32::OLE::OPC::_check_error("OPC::Group::OPCItems "
                                 . $self->{_serverprogid});
  return bless $items, 'Win32::OLE::OPC::Items';
}

=pod

=back

=cut


# -----------------------------------------------------------------------------
# OPCItems object.
#
#-----------------------------------------------------------------------------
package Win32::OLE::OPC::Items;
use Win32::OLE::Variant;
use Carp;

=pod

=head2 OPCItems

This class contains a collection of OPCItem objects.

=over 4

=item Properties

Return a hash indexed by the following properties containing the property
value:

  Parent DefaultRequestedDataType DefaultAccessPath DefaultIsActive Count

Note that the hash member indexed 'Parent' is a hash pointing back up to the
parent properties.

=cut

sub Properties {
  # Collect everything available into a hash and return it.
  my $self = shift;

  my %retv;                     # Return this.
  for my $property (qw/Parent DefaultRequestedDataType DefaultAccessPath
                    DefaultIsActive Count/) {
    $retv{$property} = $self->{items}->{$property};
    &Win32::OLE::OPC::_check_error("OPC::Items::Properties "
                                   . $self->{_serverprogid},
                             $Win32::OLE::OPC::dont_show_property_exceptions);
  }
  return %retv;
}

=pod

=item SetProperty(PROPERTY,VALUE)

Set one of these properties to the value given.

  DefaultRequestedDataType DefaultAccessPath DefaultIsActive Count

=cut

sub SetProperty {
  # Collect everything available into a hash and return it.
  my $self = shift;
  my $property = shift;         # Name of the property to set.
  my $value = shift;            # The value to put in there.

  # Check the name is valid.
  my $isvalid = 0;
  for my $valid (qw/DefaultRequestedDataType DefaultAccessPath
                 DefaultIsActive Count/) {
    if ($property eq $valid) {
      $isvalid = 1;
      last;
    }
  }
  if ($isvalid) {
    $self->{items}->{$property} = $value;
    &Win32::OLE::OPC::_check_error("OPC::Items::SetProperty "
                                   . $self->{_serverprogid});
  } else {
    carp "Attempt to set invalid property '$property' on OPC items";
  }
}

=pod

=item Item(NUMBER])

Get item by 1 based index.

=cut

sub Item {
  my $self = shift;
  my $ident = shift;

  my $item = { _parent => $self };
  $item->{item} = $self->{items}->Item(int $ident);
  $item->{_serverprogid} = $self->{_serverprogid};
  &Win32::OLE::OPC::_check_error("OPC::Items::GetOPCItem "
                                 . $self->{_serverprogid});
  if (defined($item->{item})) {
    return bless $item, 'Win32::OLE::OPC::Item';
  } else {
    return undef;
  }
}

=pod

=item GetOPCItem(SERVERHANDLE)

Get item using the server handle.

=cut

sub GetOPCItem {
  my $self = shift;
  my $ident = shift;

  my $item = { _parent => $self };
  $item->{item} = $self->{items}->GetOPCItem($ident);
  $item->{_serverprogid} = $self->{_serverprogid};
  &Win32::OLE::OPC::_check_error("OPC::Items::GetOPCItem "
                                 . $self->{_serverprogid});
  if (defined($item->{item})) {
    return bless $item, 'Win32::OLE::OPC::Item';
  } else {
    return undef;
  }
}

=pod

=item AddItem(ITEMID, CLIENTHANDLE)

Add an item identified by ITEMID, CLIENTHANDLE is a value you get back later.

=cut

sub AddItem {
  my $self = shift;
  my $itemid = shift;
  my $client_handle = shift;

  $self->{items}->AddItem($itemid, $client_handle);
  &Win32::OLE::OPC::_check_error("OPC::Items::AddItem "
                                 . $self->{_serverprogid});
}

=pod

=item AddItems(NUM, ITEMIDS, CLIENTHANDLES)

Add a load of items.

  NUM is how many.
  ITEMIDS is a reference to an array of itemids.
  CLIENTHANDLES is a reference to an array of client handles.

=cut

sub AddItems {
  my $self = shift;
  my $num = shift;
  my $itemids = shift;
  my $client_handles = shift;

  for (my $i = 0; $i < $num; $i++) {
    $self->AddItem($itemids->[$i], $client_handles->[$i]);
  }
}

#sub AddItems {
#  my $self = shift;
#  my $num = shift;
#  my $itemids = shift;
#  my $client_handles = shift;
#
#
#  $self->{items}->AddItems($num, $itemids, $client_handles);
#  &Win32::OLE::OPC::_check_error("OPC::Items::AddItems "
#                                 . $self->{_serverprogid});
#
##  # Convert the itemids and client_handles arrays into arrays of variants.
##  my $vclient_handles = Variant(VT_ARRAY|VT_I4, $num);
##  for (my $i = 0; $i < $num; $i++) {
##    $vclient_handles->Put($i, @$client_handles[$i]);
##  }
##  my $vitemids        = Variant(VT_ARRAY|VT_VARIANT, $num);
##  for (my $i = 0; $i < $num; $i++) {
##    my $bstr = Variant(VT_BSTR, @$itemids[$i]);
##    $vitemids->Put($i, $bstr);
##  }
##
##  my $server_handles  = Variant(VT_ARRAY|VT_I4|VT_BYREF, []);
##  my $errors          = Variant(VT_ARRAY|VT_I4|VT_BYREF, []);
##
##  $self->{items}->AddItems($num, $vitemids, $vclient_handles,
##                           $server_handles, $errors);
#}

=pod

=item Remove(SERVERHANDLES)

Removes the items in SERVERHANDLES.

=cut

sub Remove {
  my $self = shift;
  my $handles = shift;

  my $num = $#$handles+1;
  my $Errors = Variant(VT_ARRAY|VT_I4|VT_BYREF, [1, $num+1]);
  my $vhandles = Variant(VT_ARRAY|VT_I4, [1, $num+1]);
  for (my $i = 1; $i < $num+1; $i++) {
    $vhandles->Put($i, @$handles[$i-1]);
  }
  $self->{items}->Remove($num, $vhandles, $Errors);
  &Win32::OLE::OPC::_check_error("OPC::Items::Remove "
                                 . $self->{_serverprogid});
}

=pod

=back

=cut

# -----------------------------------------------------------------------------
# OPCItem object.
#
#-----------------------------------------------------------------------------
package Win32::OLE::OPC::Item;
use Win32::OLE::Variant;
use Carp;

=pod

=head2 OPCItem

This is the object used for reading and writing actual values.

=over 4

=item Properties

Return a hash indexed by the following properties containing the property
value:

  Parent ClientHandle ServerHandle AccessPath AccessRights ItemID IsActive
  RequestedDataType Value Quality TimeStamp CanonicalDataType EUType EUInfo

Note that the hash member indexed 'Parent' is a hash pointing back up to the
parent properties.

=cut

sub Properties {
  # Collect everything available into a hash and return it.
  my $self = shift;

  my %retv;                     # Return this.
  for my $property (qw/Parent ClientHandle ServerHandle AccessPath
                    AccessRights ItemID IsActive RequestedDataType Value
                    Quality TimeStamp CanonicalDataType EUType EUInfo/) {
    $retv{$property} = $self->{item}->{$property};
    &Win32::OLE::OPC::_check_error("OPC::Item::Properties "
                                   . $self->{_serverprogid},
                                   $Win32::OLE::OPC::show_property_exceptions);
  }
  return %retv;
}

=pod

=item Read(SOURCE)

Read the value for this item.  SOURCE is either $OPCCache or $OPCDevice, each
of which is exported by OPC.pm by default.

Read returns a hash reference which contains Value, Quality and TimeStamp
values.

=cut

sub Read {
  my $self = shift;
  my $source = shift;

  my $value        = Variant(VT_VARIANT|VT_BYREF, 0);
  my $quality      = Variant(VT_VARIANT|VT_BYREF, 0);
  my $timestamp    = Variant(VT_VARIANT|VT_BYREF, 0);

  $self->{item}->Read($source+0, $value, $quality, $timestamp);
  &Win32::OLE::OPC::_check_error("OPC::Item::Read " . $self->{_serverprogid});
  return {Value => $value->Get(),
          Quality => $quality->Get(),
          TimeStamp => $timestamp->Get()};
}

=pod

=item Write(VALUE)

Write VALUE to this item.

=cut

sub Write {
  my $self = shift;
  my $value = Variant(VT_VARIANT|VT_BYREF, shift);

  $self->{item}->Write($value);
  &Win32::OLE::OPC::_check_error("OPC::Item::Write " . $self->{_serverprogid});
}

=pod

=item ServerHandle

Returns the items server handle.

=cut

sub ServerHandle {
  my $self = shift;
  return $self->{item}->{ServerHandle};
}

=pod

=back

=cut

1;
__END__

=pod

=head1 INSTALLATION

If you have nmake you can use MakeMaker as follows:

  perl Makefile.PL
  nmake
  nmake test
  nmake install
  nmake documentation

The final step makes OPC.html and OPC.txt from OPC.pm.

If you don't have nmake then you will find OPC.html and OPC.txt are included
in the package ready built and all you have to do is copy OPC.pm into the
C<site/lib/Win32/OLE> directory with your Perl installation.  This module has
been tested with ActiveState Perl build 522.

=head1 COPYRIGHT

    (c) 1999,2000,2001,2002 Martin Tomes.  All rights reserved.
    Developed by Martin Tomes <martin@tomes.freeserve.co.uk>.

    You may distribute under the terms of the Artistic License.  See
    LICENSE.txt

=head1 AUTHOR

Martin Tomes, martin@tomes.org.uk

=head1 VERSION

Version 0.92

=cut
