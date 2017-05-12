#!/usr/bin/perl
#
# Revision History:
#
#   26-Nov-2002 Dick Munroe (munroe@csworks.com)
#       Initial Version Created.
#
#   18-May-2003 Dick Munroe (munroe@csworks.com)
#       Make sure package variables can't leak.
#
#   19-May-2003 Dick Munroe (munroe@csworks.com)
#       Use Carp.
#       Isolate KIF related classes in a KIF namespace.
#

package KIF::Bootloader::aboot ;

use vars qw($VERSION @ISA) ;

our $VERSION = "1.03" ;

use strict ;

use Carp ;
use File::Copy ;
use FileHandle ;
use KIF::Bootloader ;

our @ISA = qw(KIF::Bootloader) ;

sub new
{
    my $thePackage = shift ;

    my $theObject = $thePackage->SUPER::new() ;

    if (-e "/etc/aboot.conf")
    {
	$theObject->filename("/etc/aboot.conf") ;
	if (-e "/boot/etc/aboot.conf")
	{
	    $theObject->synchedFilename("/boot/etc/aboot.conf") ;
	} ;
    }
    elsif (-e "/boot/etc/aboot.conf")
    {
	$theObject->filename("/boot/etc/aboot.conf") ;
    }
    else
    {
	croak "No aboot.conf file found" ;
    } ;

    return $theObject ;
} ;

sub synchedFilename
{
    my $theObject = shift ;

    $theObject->{'synchedFilename'} = $_[0] if (defined($_[0])) ;

    return $theObject->{'synchedFilename'} ;
} ;

sub modify
{
    my $theObject = shift ;
    my $theBuildObject = shift ;

    #
    # Modify the aboot.conf file only if we're not just rebuilding the
    # current default kernel.
    #

    my $theCurrentKernel = readlink "/boot/vmlinuz" ;

    $theCurrentKernel =~ s,.*/,, ;
    $theCurrentKernel =~ s,.*?-,, ;

    return if ($theCurrentKernel eq $theBuildObject->releaseTag);

    my $theAbootFile = $theObject->_file($theObject->filename) ;

    my @theAbootArray = $theAbootFile =~ m,(^\d+:\d+.*$),mg ;

    @theAbootArray = sort @theAbootArray ;

    foreach (@theAbootArray)
    {
	#
	# The current kernel is already in the aboot.conf file, so
	# we can safely not modify the file.
	#

	return if (m,-$theCurrentKernel( |$),) ;
    } ;

    #
    # At this point we know we have to modify the aboot.conf file
    # and we know that the aboot.conf file should have an available
    # place for a new entry, so we can safely modify things.
    #

    my $theIndex ;
    my $theLastItem = $theAbootArray[0] ;

    for ($theIndex = 1; $theIndex < 10; $theIndex++)
    {
	last if (!defined($theAbootArray[$theIndex])) ;
	$theLastItem = $theAbootArray[$theIndex] ;
    } ;

    my $theNewEntry ;

    ($theNewEntry = $theAbootArray[0]) =~ s/vmlinuz/vmlinuz-$theCurrentKernel/ ;

    $theNewEntry =~ s/0/$theIndex/ ;

    $theAbootFile =~ s/^$theLastItem$/$theLastItem\n$theNewEntry/m ;

    $theBuildObject->_print($theAbootFile, 3) ;

    if (!$theBuildObject->testFlag)
    {
	move($theObject->filename(), $theObject->filename() . ".old") ;

	$theBuildObject->_print("Moving " . $theObject->filename() . " => " . $theObject->filename() . ".old\n",1) ;

	my $theFileHandle = new FileHandle "> " . $theObject->filename() or croak "Can't open "  . $theObject->filename() ;

	$theFileHandle->print($theAbootFile) ;

	$theBuildObject->_print("Writing " . $theObject->filename() . "\n",1) ;

	undef $theFileHandle ;

	if (defined($theObject->synchedFilename()))
	{
	    move($theObject->synchedFilename(), $theObject->synchedFilename() . ".old") ;

	    $theBuildObject->_print("Moving " . $theObject->synchedFilename() . " => " . $theObject->synchedFilename() . ".old\n",1) ;

	    copy($theObject->filename(), $theObject->synchedFilename()) ;

	    $theBuildObject->_print("Copying " . $theObject->filename() . " => " . $theObject->synchedFilename() . "\n",1) ;
	} ;
    } ;
} ;

sub validate
{
    #
    # A valid aboot.conf has as it's initial entry the following:
    #
    #    0:[partition]/vmlinuz [kernel arguments]
    #

    my $theObject = shift ;

    my $theBuildObject = shift ;

    $theObject->SUPER::validate($theBuildObject) ;

    my $theFileName = $theObject->filename() ;

    my $theAbootFile = $theObject->_file($theFileName) ;

    if ($theAbootFile !~ m,^0:\d+/vmlinuz,m)
    {
	print STDERR <<"EOT" ;

$theFileName must be in a standard form for ik to work properly.
The "default" entry must of the form:

  0:[partitionNumber]/vmlinuz [kernelParameters]

Please add an appropriate line to $theFileName and rerun ik.
EOT
        croak "$theFileName is invalid." ;
    } ;

    my $theCurrentKernel = readlink "/boot/vmlinuz" ;

    $theCurrentKernel =~ s,.*/,, ;
    $theCurrentKernel =~ s,.*?-,, ;

    #
    # Bail if we're just rebuilding the current default kernel.
    #

    return if ($theCurrentKernel eq $theBuildObject->releaseTag()) ;

    #
    # Now check for either a spare hole in the aboot.conf file
    # for this kernel or that this kernel is ALREADY in the
    # aboot.conf file
    #

    my @theAbootArray = $theAbootFile =~ m,(^\d+:\d+.*$),mg ;

    foreach (@theAbootArray)
    {
	#
	# Done if the current kernel is already in the aboot configuration
	# file.
	#

	return if (m/-$theCurrentKernel( |$)/) ;
    } ;

    if (scalar(@theAbootArray) >= 10)
    {
	print STDERR << "EOT" ;
Only 10 entries, numbered from 0 to 9, may exist in an aboot.conf
file.  10 entries have been defined.  You must remove one of these
lines and rerun ik.

EOT
        croak "No entries left in /etc/aboot.conf" ;
    } ;
} ;

1;
