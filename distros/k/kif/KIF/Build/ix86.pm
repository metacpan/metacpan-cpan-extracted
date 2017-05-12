#!/usr/bin/perl
#
# Revision History:
#
#   26-Nov-2002 Dick Munroe (munroe@csworks.com)
#       Initial Version Created.
#
#   27-Nov-2002 Dick Munroe (munroe@csworks.com)
#       Support LILO as a bootloader.
#
#   03-Dec-2002 Dick Munroe (munroe@csworks.com)
#       Fix search for alternate boot loader configuration files.
#
#   18-May-2003 Dick Munroe (munroe@csworks.com)
#       Make sure package variables can't leak.
#
#   19-May-2003 Dick Munroe (munroe@csworks.com)
#       Use Carp.
#       Isolate kif related classes in a KIF namespace.
#

package KIF::Build::ix86 ;

use vars qw($VERSION @ISA) ;

our $VERSION = "1.02" ;

use strict ;

use Carp ;
use File::Copy ;
use KIF::Build ;
use KIF::Bootloader::grub ;
use KIF::Bootloader::lilo ;

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

    my @theBootloaderConfigurationFiles = ("/boot/grub/grub.conf", "/etc/lilo.conf") ;
    my $theBootloaderIndex ;
    my $theIndex ;
    my $theNumberOfBootloaders ;
    
    for ($theIndex = 0; $theIndex < scalar(@theBootloaderConfigurationFiles); $theIndex++)
    {
	if (-e $theBootloaderConfigurationFiles[$theIndex])
	{
	    $theNumberOfBootloaders++ ;
	    $theBootloaderIndex = $theIndex ;
	} ;
    } ;

    #
    # It is possible to use BOTH LILO and Grub on the same system
    # Check to see if LILO was used to boot this system and choose
    # LILO if necessary.
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

    $theBootloader = new KIF::Bootloader::grub if ($theBootloaderIndex == 0) ;
    $theBootloader = new KIF::Bootloader::lilo if ($theBootloaderIndex == 1) ;

    croak "No bootloader object allocated" if (!defined($theBootloader)) ;

    $theObject->bootloader($theBootloader) ;

    return $theObject ;
} ;

sub doKernel
{
    my $theObject = shift ;

    $theObject->run('make bzImage') ;
} ;

sub doMovefiles
{
    my $theObject = shift ;

    $theObject->SUPER::doMovefiles() ;

    my $theBuildDirectory = $theObject->buildDirectory() ;
    my $theReleaseTag = $theObject->releaseTag() ;

    if (-e "$theBuildDirectory/arch/i386/boot/bzImage")
    {
	copy("$theBuildDirectory/arch/i386/boot/bzImage", "/boot/vmlinuz-$theReleaseTag") or croak "Copy failed: $!"
	    if (!$theObject->testFlag()) ;
	$theObject->_print("Copied $theBuildDirectory/arch/i386/boot/bzImage => /boot/vmlinuz-$theReleaseTag\n", 1) ;
    } ;
} ;

1;
