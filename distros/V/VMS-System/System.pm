package VMS::System;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;
require DynaLoader;

@ISA = qw(Exporter DynaLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw();
@EXPORT_OK = qw(&sys_info_names        &get_all_sys_info_items
                &get_one_sys_info_item &decode_sys_info_bitmap
                &node_list);
$VERSION = '1.05';

bootstrap VMS::System $VERSION;

# Preloaded methods go here.
sub new {
  my($pkg,$node) = @_;
  my $self = { __NODE => $node };
  bless $self, $pkg; 
}

sub one_info { get_one_sys_info_item($_[1], defined $_[0]->{__NODE} ? $_[0]->{__NODE} : ''); }
sub all_info { get_all_sys_info_items($_[0]->{__NODE}) }

sub TIEHASH { my $obj = new VMS::System; $obj; }
sub FETCH   { $_[0]->one_info($_[1], $_[0]->{__NODE}); }
sub EXISTS  { grep(/$_[1]/, sys_info_names($_[0]->{__NODE})) }

# Can't STORE, DELETE, or CLEAR--this is readonly. We'll Do The Right Thing
# later, when I know what it is...
#sub STORE   {
#  my($self,$priv,$val) = @_;
#  if (defined $val and $val) { $self->add([ $priv ],$self->{__PRMFLG});    }
#  else                       { $self->remove([ $priv ],$self->{__PRMFLG}); }
#}
#sub DELETE  { $_[0]->remove([ $_[1] ],$_[0]->{__PRMFLG}); }
#sub CLEAR   { $_[0]->remove([ keys %{$_[0]->current_privs} ],$_[0]->{__PRMFLG}) }

sub FIRSTKEY {
  $_[0]->{__SYS_INFO_ITERLIST} = [ sys_info_names($_[0]->{__NODE}) ];
  $_[0]->one_info(shift @{$_[0]->{__SYS_INFO_ITERLIST}},$_[0]->{__NODE} );
}
sub NEXTKEY { $_[0]->one_info(shift @{$_[0]->{__SYS_INFO_ITERLIST}}, $_[0]->{__NODE}); }

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__

=head1 NAME

VMS::System - Retrieves status and identification information from OpenVMS system(s).

=head1 SYNOPSIS

  use VMS::System;

VMS::System will can access either system info for any node in the cluster
(what info is available depends on whether you're local to the node being
accessed or not), or parameters set by SYSGEN for the local node.

In the cases below where the node name is marked as optional (i.e. in
square brackets), leaving it off returns only the information that's valid
for the node the process is running on.


Return a list of all the node names in the cluster:

  @NodeList = VMS::System::node_list();

Routine to return a reference to a hash with all the system info for the
node loaded into it:

  $SysInfo = VMS::System::get_all_sys_info_items([nodename]);
  $archtype = $SysInfo->{ARCH_TYPE};

Fetch a single piece of info:

  $archtype = VMS::System::get_one_sys_info_item("ARCH_TYPE"[, nodename]);

Decode a bitmap into a hash filled with names, with their values set to
true or false based on the bitmap.

  $hashref = VMS::System::decode_sys_info_bitmap("ARCHFLAGS", Bitmap);

Get a list of valid info names:

  @InfoNames = VMS::System::sys_info_names([nodename]);

Tied hash interface:
  
  tie %SysInfohash, VMS::System[, nodename];
  $diolm = $SysInfohash{ARCH_TYPE};

Object access:

  $SysInfoobj = new VMS::System [nodename];
  $archtype = $SysInfoobj->one_info("ARCH_TYPE");
  $hashref = $SysInfoobj->all_info();

=head1 DESCRIPTION

Retrieve info for a node. Access is via function call, object and method,
or tied hash. Choose your favorite.

=head1 Special Stuff

While Most items are scalars, there are a few exceptions. THERMAL_VECTOR,
TEMPERATURE_VECTOR, FAN_VECTOR, and POWER_VECTOR are arrays, with each array
element corresponding to a particular CPU (for THERMAL_VECTOR and
TEMPERATURE_VECTOR), fan, or power supply. TEMPERATURE_VECTOR is an array
of CPU temperatures, while the other three are arrays that will contain
Good, Bad, Not Present, or Dunno, depending on the status of the fan, power
supply, or CPU temperature.

=head1 BUGS

May leak memory. May not, though.

=head1 LIMITATIONS

Quadword and hexword values are returned as string values rather than
integers.

List info (like rightslists) is not returned.

The decode bitmap function doesn't currently decode anything.

You can't get all system info for all nodes in the cluster, or any system
parameters for any non-local node. This is a VMS limitation, though one I
hope will be lifted at some point. (If you've got a VMS source listing,
send me e-mail and we'll talk)

=head1 AUTHOR

Dan Sugalski <dan@sidhe.org>
Craig A. Berry <craigberry@mac.com>

=head1 SEE ALSO

perl(1), VMS::Process.

=cut
