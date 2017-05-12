#!/usr/bin/perl -w


use strict;

use Win32API::File qw(
    createFile
    fileLastError
    fileConstant
    DeviceIoControl IOCTL_DISK_GET_MEDIA_TYPES IOCTL_DISK_FORMAT_TRACKS
    CloseHandle
);


exit main();


sub PickMedia
{
    my( $disk )= @_;
    my( @MediaType, %MediaType )= @{$Win32API::File::EXPORT_TAGS{MEDIA_TYPE}};
    for(  @MediaType  ) {
	$MediaType{fileConstant($_)}= $_;
    }
    $disk= "PhysicalDrive$disk"   if  $disk =~ /^\d+$/;
    my $h= createFile( "//./$disk", "q" )
      or  die "Can't read disk ($disk): ", fileLastError(), "\n";
    my $fmtGeom= "LL L L L L";
    my $lGeom= length pack $fmtGeom, (0)x6;
    my $aGeom;
    DeviceIoControl( $h, IOCTL_DISK_GET_MEDIA_TYPES,
      [], 0, $aGeom, 32*$lGeom, [], [] )
      or  die "Can't get media types for disk ($disk): ", fileLastError(), "\n";
    CloseHandle( $h )
      or  warn "Failed to close disk ($disk): ", fileLastError(), "\n";
    @MediaType= ();
    my $idx= 0;
    print "\nPlease select the desired density:\n\n";
    while(  $aGeom  ) {
	my( $cLoDiskCyls, $cHiDiskCyls, $uMediaType,
	    $cCylTracks, $cTrackSects, $cSectBytes )=
	  unpack $fmtGeom, substr( $aGeom, 0, $lGeom );
	substr( $aGeom, 0, $lGeom )= "";
	my $sMediaType= $MediaType{$uMediaType} || "Other($uMediaType)";
	my $cDiskCyls= $cHiDiskCyls*65356*65356 + $cLoDiskCyls;
	++$idx;
	my $meg= $cDiskCyls * $cCylTracks * $cTrackSects * $cSectBytes
	  / 1_024_000;	# Note the strange "floppy MB" of 1000*1024 bytes!
	print "  $idx) $sMediaType: $cDiskCyls cyl.s of $cCylTracks ",
	  "tracks of $cTrackSects sect.s of $cSectBytes bytes ($meg MB)\n";
	push @MediaType, [ $uMediaType, $cDiskCyls, $cCylTracks ];
	if(  0 != $cHiDiskCyls  ) {
	    warn "\t[The above media type cannot be formatted.]\n";
	}
    }
    print "\n";
    while( 1 ) {
	print "Enter the number of the density to use: ";
	my $resp= <STDIN>;
	die "Error reading response: $!\n"
	  unless  defined $resp;
	if(  $resp =~ /^[1-9]\d*$/  &&  $MediaType[$resp-1]  ) {
	    return @{$MediaType[$resp-1]};
	}
	warn "Invalid choice.\n";
    }
}


sub PickRange
{
    my( $what, $count )= @_;
    return( 0, 0 )   if  $count-- < 2;
    while( 1 ) {
	print
	  "\nEnter the range of ${what}s to format (or <CR> for 0..$count): ";
	my $resp= <STDIN>;
	die "Error reading response: $!\n"   unless  defined $resp;
	return( 0, $count )
	  if  $resp =~ /^\s*$/;
	if(  $resp !~ /^\s*(\d+)\D+(\d+)\s*$/  ) {
	    warn "Invalid response; does not contain two integers.\n";
	} elsif(  0 <= $1  &&  $1 <= $2  &&  $2 <= $count  ) {
	    return( $1, $2 );
	} else {
	    warn "Invalid range; not within 0..$count.\n";
	}
    }
}

sub main
{
    die "Usage:  $0 A:\n",
      "To format a floppy diskette in the A: drive.\n",
      "Note that a FAT file system is _not_ placed on the floppy.\n"
      unless  1 == @ARGV;
    my $disk= $ARGV[0];
    my( $media, $cyls, $hds )= PickMedia( $disk );
    my $h= createFile( "//./$disk", "rwke" )
      or  die "Can't access raw floppy (//./$disk): ",fileLastError(),"\n";
    # FORMAT_PARAMETERS:  MediaType, StartCyl, EndCyl, StartHead, EndHead
    my( $mincyl, $maxcyl )= PickRange( "cylinder", $cyls );
    my( $minhd, $maxhd )= PickRange( "head", $hds );
    warn "\nFormatting $disk cylinders $mincyl..$maxcyl, ",
      "heads $minhd..$maxhd ...\n";
    my $FmtParms= pack( "L*", $media, $mincyl, $maxcyl, $minhd, $maxhd );
    DeviceIoControl( $h, IOCTL_DISK_FORMAT_TRACKS,
      $FmtParms, 0, [], 0, [], [] )
      or  die "Can't format floppy (//./$disk): ",fileLastError(),"\n";
    return 0;
}
