package VMS::Device;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;
require DynaLoader;
require AutoLoader;

@ISA = qw(Exporter AutoLoader DynaLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw();
@EXPORT_OK = qw(&device_types &device_classes &device_list &device_info
                &decode_device_bitmap &device_info_item &mount &dismount
                &allocate &deallocate &initialize);
$VERSION = '0.10';

bootstrap VMS::Device $VERSION;

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__

=head1 NAME

VMS::Device - Perl interface to VMS device system calls ($GETDVI and friends)

=head1 SYNOPSIS

  use VMS::Device;
  @type_list = device_types();
  @class_list = device_classes();
  @dev_list = device_list($DeviceName[, $DeviceClass[, $DeviceType]]);
  $DevInfoHashRef = device_info($DeviceName);
  $BitmapHashRef = decode_device_bitmap($InfoName, $BitmapValue)
  $Status = mount(\%Device_properties);
  $Status = dismount($DevName[, \%Dismount_flags]); [Unimplemented]
  $DeviceAllocated = allocate($DevName[, $FirstAvail[, $AccMode]]);
  $Status = deallocate($DevName[, $AccMode]);
  $Status = initialize($DevName[, $VolumeName[, \%DevProperties]]);

=head1 DESCRIPTION

VMS::Device mounts and dismounts, allocates and deallocates, initializes,
and lists and gets info on devices. It subsumes the DCL commands MOUNT,
DISMOUNT, ALLOCATE, DEALLOCATE, and INITIALIZE, as well as the lexical
functions F$DEVICE and F$GETDVI.

=head2 Functions

=item device_types

This function returns a list of all the valid device types that can be
specified for the C<device_list> function.

=item device_classes

This function returns a list of all the valid device classes that can be
specified for the C<device_list> function.

=item device_list

The C<device_list> function returns a list of all devices whose names match
the passed device name (Standard VMS wildcards of * and % are OK) and that
meets the criteria in the optional device type and device class.

Both the device class and device type may be ommitted if you want, or
passed as C<undef>. If you use the type and not the class, class must be
passed as C<undef>.

=item device_info

The C<device_info> function returns a reference to a hash containing all
the information available about the device you asked about.

=item decode_device_bitmap

The C<decode_device_bitmap> takes an item code and an integer, and returns
a reference to a hash. The function assumes the integer is a bitmap as
returned for that particular item, and decodes it. Each element in the
returned hash is equivalent to one of the bits in the integer--its value
will be true or false depending on the setting of the bit.

=item mount

C<mount> takes a reference to a hash with the parameters for the mount, and
attempts to mount the device. At the very least you want a C<DEVNAM>
parameter to specify the device being mounted.

=item dismount

C<dismount> dismounts the specified device. The optional reference to a
flag hash governs how the dismount behaves (whether it's a cluster-wide
dismount, for example)

=item allocate

C<allocate> allocates the named device.

If the C<$FirstAvail> flag is true, then the device name is treated as a
device type rather than an actual device, and the first device matching the
type that's available will be allocated.

C<$AccMode> is the access mode that the device is allocated in. This can be
one of:

    KERNEL
    EXEC
    SUPER
    USER

to indicate the mode the device should be allocated in.

=item deallocate

C<deallocate> deallocates a previously allocated device. The optional
second parameter can be one of:

    KERNEL
    EXEC
    SUPER
    USER

to indicate the mode the device should be deallocated in.

=item initialize

Initializes the specified device. If the second parameter isn't C<undef>,
it's taken to be the name the initialized volume should have. If the third
parameter isn't C<undef>, it's taken to be a reference to a hash that has
the properties the newly-initialized volume should have.

=head1 EXAMPLES

Here's a sample that returns the total amount of free space on all disk
devices:

    #! perl -w
    use VMS::Device qw(device_list device_info);

    $TotalFreeBlocks = 0;
    foreach my $devname (device_list("*", "DISK")) {
      $TotalFreeBlocks += device_info($devname)->{FREEBLOCKS};
    }

    print "Total free is $TotalFreeBlocks\n";


here's one that prints out the disk with the largest amount of free space:

    #! perl -w
    use VMS::Device qw(device_list device_info);

    $FreeBlocks = 0;
    $FreeName = "DUAWHOKNOWS";
    foreach my $devname (device_list("*", "DISK")) {
      $CheckBlocks = device_info($devname)->{FREEBLOCKS};
      if ($CheckBlocks > $FreeBlocks) {
        $FreeBlocks = $CheckBlocks;
        $FreeName = $devname;
      }
    }

    print "$FreeBlocks on $FreeName\n";


and here's one that shows all disks with less than 10% free:


    #! perl -w
    use VMS::Device qw(device_list device_info decode_device_bitmap);
    
    foreach my $devname (device_list("*", "DISK")) {
      $DevHash = device_info($devname);
      $FreeBlocks = $DevHash->{FREEBLOCKS};
      $MaxBlocks = $DevHash->{MAXBLOCK};
      next unless $DevHash->{MOUNTCNT};
      next unless $MaxBlocks;
      $PctFree = int(($FreeBlocks/$MaxBlocks) * 100);
      if ($PctFree < 10) {
        print "Only $PctFree\% on $devname ($FreeBlocks of $MaxBlocks)\n";
      }
    }

=head1 AUTHOR

Dan Sugalski E<lt>dan@sidhe.org<gt>

Currently maintained by Craig Berry E<lt>craigberry@mac.com<gt>

=head1 SEE ALSO

perl(1).

=cut
