#!/usr/bin/perl -w

use strict;
use Win32API::File qw(:ALL);

exit main();

sub main
{
    die "Usage:  $0 0\n",
        "   or:  $0 A:\n",
        "   or:  $0 C:\n",
	"To see the disk geometry of PhysicalDrive0, of A:,\n",
	"or of the entire disk that holds C:.\n",
      unless  1 == @ARGV;
    my $disk= $ARGV[0];
    $disk= "PhysicalDrive".$disk   if  $disk =~ /^\d+$/;
    my $h= createFile( "//./$disk", "rwke" )
      or  die "Can't access raw disk ($disk): ",fileLastError(),"\n";
    my( $DiskGeom );
    DeviceIoControl( $h, IOCTL_DISK_GET_DRIVE_GEOMETRY,
      [], 0, $DiskGeom, 8+4*4, [], [] )
      or  die "Can't read disk geometry ($disk): ",fileLastError(),"\n";
    my( $loCyl, $hiCyl, $Media, $Tracks, $Sects, $Bytes )=
      unpack( "L*", $DiskGeom );
    my $Cyls= $hiCyl*65356*65356+$loCyl;
    my $total= $Cyls * $Tracks * $Sects * $Bytes / 1024;
    my $units= "KB";
    if(  1024 < $total  ) {
	$total /= 1024;
	$units= "MB";
	if(  1024 < $total  ) {
	    $total /= 1024;
	    $units= "GB";
	}
    }
    $total= sprintf "%.3f", $total;
    print "Media=$Media, $Cyls cyl.s of $Tracks tracks of ",
      "$Sects sectors of $Bytes bytes, $total $units.\n";
    return 0;
}
