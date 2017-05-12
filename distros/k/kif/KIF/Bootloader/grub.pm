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

package KIF::Bootloader::grub ;

use vars qw($VERSION @ISA) ;

our $VERSION = "1.03" ;

use strict ;

use Carp ;
use File::Basename ;
use File::Copy ;
use FileHandle ;
use KIF::Bootloader ;
use StanzaFile::Grub ;

our @ISA = qw(KIF::Bootloader) ;

sub new
{
    my $thePackage = shift ;

    my $theObject = $thePackage->SUPER::new() ;

    if (-e "/boot/grub/grub.conf")
    {
	$theObject->filename("/boot/grub/grub.conf") ;
    }
    else
    {
	croak "No grub.conf file found" ;
    } ;

    return $theObject ;
} ;

sub initrdFile
{
    my $theObject = shift ;
    
    my $theGrubFile = new StanzaFile::Grub(file_name=>$theObject->filename()) ;

    return basename($theGrubFile->stanza(($theGrubFile->order())[$theGrubFile->header()->item('default')])->item('initrd')) ;
} ;

sub modify
{
    my $theObject = shift ;
    my $theBuildObject = shift ;

    #
    # Modify the grub.conf file only if we're not just rebuilding the
    # current default kernel.
    #

    my $theReleaseTag = $theBuildObject->releaseTag() ;

    my $theCurrentKernel = readlink "/boot/vmlinuz" ;

    $theCurrentKernel =~ s,.*/,, ;
    $theCurrentKernel =~ s,.*?-,, ;

    return if ($theCurrentKernel eq $theReleaseTag);

    my $theGrubFile = new StanzaFile::Grub(file_name=>$theObject->filename()) ;

    foreach ($theGrubFile->order())
    {
	#
	# The current kernel is already in the grub.conf file, so
	# we can safely not modify the file.
	#
	# FIX ME Should we point the default to this entry?
	#

	return if ($theGrubFile->stanza($_)->item('kernel') =~ m,-$theReleaseTag( |$),) ;
    }

    #
    # At this point we know we have to modify the grub.conf file
    #

    my $theIndex = $theGrubFile->header()->item('default') ;
    my $theNewStanza = ($theGrubFile->stanza(($theGrubFile->order())[$theIndex]))->new() ;

    #
    # New Stanza is a clone of the default entry, modify it so that
    # everything will point to the new kernel.
    #

    my $theCurrentRelease = $theNewStanza->item('kernel') ;
    $theCurrentRelease =~ s/.*?vmlinuz-(.*?)( |$).*/$1/ ;

    foreach ($theNewStanza->order())
    {
	my $theString ;

	($theString = $theNewStanza->item($_)) =~ s/$theCurrentRelease/$theReleaseTag/ ;

	$theNewStanza->item($_, $theString) ;

    } ;

    $theNewStanza->name("KIF ($theReleaseTag)");

    $theGrubFile->add($theNewStanza) ;

    $theGrubFile->header()->item('default', scalar($theGrubFile->order())-1) ;

    if (!$theBuildObject->testFlag())
    {
	move($theObject->filename(), $theObject->filename() . ".old") ;

	$theBuildObject->_print("Moving " . $theObject->filename() . " => " . $theObject->filename() . ".old\n",1) ;

	my $theString = $theGrubFile->write(file_name=>$theObject->filename()) ;

	$theBuildObject->_print($theString, 3) ;
    }
    else
    {
	$theBuildObject->_print($theGrubFile->asString(), 3) ;
    } ;
} ;

sub validate
{
    #
    # A valid grub.conf has a default entry and a valid stanza
    # at that entry.
    #

    my $theObject = shift ;

    my $theBuildObject = shift ;

    $theObject->SUPER::validate($theBuildObject) ;

    my $theFileName = $theObject->filename() ;

    my $theGrubFile = new StanzaFile::Grub(file_name=>$theFileName) ;
    my $theIndex ;

    if (!(defined($theIndex = $theGrubFile->header()->item('default'))))
    {
	print STDERR <<"EOT" ;

$theFileName must be in a standard form for kif to work properly.
There must be a default entry in the header portion of the file
of the form:

default=n

where n is the index to the default grub configuration to use
when booting.  Remember that n starts with 0 and the first entry
is number 0.

Please add an appropriate line to $theFileName and rerun kif.
EOT
        croak "$theFileName is invalid." ;
    } ;

    #
    # Now make sure that the particular configuration is actually
    # in the configuration file.
    #

    if (!(defined($theGrubFile->stanza(($theGrubFile->order())[$theIndex]))))
    {
	print STDERR << "EOT" ;
The stanza indicated by the default header item in $theFileName does 
not exist.  You must correct the default value and rerun kif.
EOT
        croak "Invalid default configuration header in $theFileName" ;
    } ;
} ;

1;
