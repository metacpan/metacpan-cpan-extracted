#!/usr/bin/perl
#
# Revision History:
#
#   26-Nov-2002 Dick Munroe (munroe@csworks.com)
#       Initial Version Created.
#
#   18-May-2003 Dick Munroe (munroe@csworks.com)
#       Make sure that package variables can't leak.
#
#   19-May-2003 Dick Munroe (munroe@csworks.com)
#       Use Carp.
#       Isolate kif related classes in a KIF namespace.
#

package KIF::Build::alpha ;

use vars qw($VERSION @ISA) ;

our $VERSION = "1.03" ;

use strict ;

use Carp ;
use File::Copy ;
use FileHandle ;
use KIF::Build ;

our @ISA = qw(KIF::Build) ;

sub new
{
    my $thePackage = shift ;

    my $theObject = $thePackage->SUPER::new(@_) ;

    #
    # Figure out what bootloader is in use by this system and
    # allocate an object to be used when (or if) the boot loader
    # configuration files are modified.
    #

    my @theBootloaderConfigurationFiles = (["/etc/aboot.conf", "/boot/etc/aboot.conf"], "/etc/milo.conf") ;
    my $theBootloaderIndex ;
    my $theIndex ;
    my $theNumberOfBootloaders ;
    
    for ($theIndex = 0; $theIndex < scalar(@theBootloaderConfigurationFiles); $theIndex++)
    {
        if (ref($theBootloaderConfigurationFiles[$theIndex]) eq "ARRAY")
	{
	    foreach (@{$_})
	    {
		if (-e $_)
		{
		    $theNumberOfBootloaders++ ;
		    $theBootloaderIndex = $theIndex ;
		    last ;
		} ;
	    } ;
	}
	elsif (-e $_)
	{
	    $theNumberOfBootloaders++ ;
	    $theBootloaderIndex = $theIndex ;
	} ;
    } ;

    #
    # It is possible to use BOTH MILO and aboot on the same system
    # Check to see if MILO was used to boot this system and choose
    # MILO if necessary.
    #
    # FIXME this is actually NOT known to work.  Can someone with
    #       a MILO boot configuration check to see if this is actually
    #       working?
    #

    if ($theNumberOfBootloaders > 1)
    {
	my $theFileHandle = new FileHandle "< /proc/cmdline" or croak "Can't open /proc/cmdline" ;

	$theBootloaderIndex = 0 ;

	while ($_ = $theFileHandle->getline)
	{
	    if (m/BOOT_IMAGE/)
	    {
		$theBootloaderIndex = 1 ;
		last ;
	    } ;
	} ;

	undef $theFileHandle ;
    } ;

    #
    # Now allocate an object used to manipulate that particular file.
    #

    my $theBootloader ;

    $theBootloader = new Bootloader::aboot if ($theBootloaderIndex == 0) ;
    $theBootloader = new Bootloader::MILO if ($theBootloaderIndex == 1) ;

    croak "No bootloader object allocated" if (!defined($theBootloader)) ;

    $theObject->bootloader($theBootloader) ;

    return $theObject ;
} ;

sub doMovefiles
{
    my $theObject = shift ;

    $theObject->SUPER::doMovefiles() ;

    my $theBuildDirectory = $theObject->buildDirectory() ;
    my $theReleaseTag = $theObject->releaseTag() ;

    if (-e "$theBuildDirectory/vmlinux")
    {
	$theObject->run("gzip -c $theBuildDirectory/vmlinux > /boot/vmlinuz-$theReleaseTag") ;
    } ;
} ;

sub validate
{
    my $theObject = shift ;

    croak '/boot/vmlinuz must exist.' if (!-e '/boot/vmlinuz') ;
    
    croak '/boot/vmlinuz must be a link.' if (!-l '/boot/vmlinuz') ;

    $theObject->SUPER::validate() ;
} ;

1;
