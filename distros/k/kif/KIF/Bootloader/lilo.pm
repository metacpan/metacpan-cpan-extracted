#!/usr/bin/perl
#
# Revision History:
#
#   27-Nov-2002 Dick Munroe (munroe@csworks.com)
#       Initial Version Created.
#
#   18-May-2003 Dick Munroe (munroe@csworks.com)
#       Make sure package variables can't leak.
#
#   19-May-2003 Dick Munroe (munroe@csworks.com)
#       Use Carp.
#       Isolate kif related classes in a KIF namespace
#

package KIF::Bootloader::lilo;

use vars qw($VERSION @ISA) ;

our $VERSION = "1.03" ;

use strict ;

use Carp ;
use File::Basename ;
use File::Copy ;
use FileHandle ;
use KIF::Bootloader ;
use StanzaFile::Lilo ;

our @ISA = qw(KIF::Bootloader) ;

sub new
{
    my $thePackage = shift ;

    my $theObject = $thePackage->_new() ;

    if (-e "/etc/lilo.conf")
    {
	$theObject->filename("/etc/lilo.conf") ;
    }
    else
    {
	croak "No lilo.conf file found" ;
    } ;

    return $theObject ;
} ;

sub initrdFile
{
    my $theObject = shift ;
    
    my $theLiloFile = new StanzaFile::Lilo(file_name=>$theObject->filename()) ;

    my $theDefaultLabel = $theLiloFile->header()->item('default') ;

    foreach ($theLiloFile->order())
    {
	if ($theLiloFile->stanza($_)->item('label') eq $theDefaultLabel)
	{
	    croak "No initrd item in stanza: $theDefaultLabel"
		if (!defined($theLiloFile->stanza($_)->item('initrd'))) ;
	    return basename($theLiloFile->stanza($_)->item('initrd')) ;
	} ;
    } ;

    croak "Can't find a stanza with label: $theDefaultLabel" ;
} ;

sub modify
{
    my $theObject = shift ;
    my $theBuildObject = shift ;

    #
    # Modify the lilo.conf file only if we're not just rebuilding the
    # current default kernel.
    #

    my $theReleaseTag = $theBuildObject->releaseTag() ;

    my $theCurrentKernel = readlink "/boot/vmlinuz" ;

    $theCurrentKernel =~ s,.*/,, ;
    $theCurrentKernel =~ s,.*?-,, ;

    return if ($theCurrentKernel eq $theReleaseTag);

    my $theLiloFile = new StanzaFile::Lilo(file_name=>$theObject->filename()) ;

    foreach ($theLiloFile->order())
    {
	#
	# The current kernel is already in the lilo.conf file, so
	# we can safely not modify the file.
	#

	return if (m,-$theReleaseTag( |$),) ;
    }

    #
    # At this point we know we have to modify the lilo.conf file
    #

    my $theNewStanza = $theLiloFile->header()->item('default') ; # Extract the label of the default stanza.

    foreach ($theLiloFile->order())
    {
	if ($theLiloFile->stanza($_)->item('label') eq $theNewStanza)
	{
	    $theNewStanza = $theLiloFile->stanza($_)->new() ;	
                                # Extract a clone of the default lilo entry.
	    last ;		# Done looking.
	} ;
    } ;

    #
    # New Stanza is a clone of the default entry, modify it so that
    # everything will point to the new kernel.
    #

    my $theCurrentRelease = $theNewStanza->name() ;
    $theCurrentRelease =~ s/.*?vmlinuz-(.*?)( |$).*/$1/ ;
    my $theString ;

    ($theString = $theNewStanza->name()) =~ s/$theCurrentRelease/$theReleaseTag/ ;
    $theNewStanza->name($theString) ; # Change the name of the new kernel image.

    foreach ($theNewStanza->order())
    {
	($theString = $theNewStanza->item($_)) =~ s/$theCurrentRelease/$theReleaseTag/ ; 

	$theNewStanza->item($_, $theString) ;
    } ;

    $theNewStanza->item('label', "KIF-$theReleaseTag");

    $theLiloFile->add($theNewStanza) ;

    $theLiloFile->header()->item('default', $theNewStanza->item('label')) ;

    if (!$theBuildObject->testFlag())
    {
	move($theObject->filename(), $theObject->filename() . ".old") ;

	$theBuildObject->_print("Moving " . $theObject->filename() . " => " . $theObject->filename() . ".old\n",1) ;

	$theString = $theLiloFile->write(file_name=>$theObject->filename()) ;

	$theBuildObject->_print($theString, 3) ;
    }
    else
    {
	$theBuildObject->_print($theLiloFile->asString(), 3) ;
    } ;

    #
    # LILO requires that the new bootloader information be linked to
    # the boot block.  The following does this and ups the verbosity
    # to match.
    #

    $theString = 'lilo' ;

    $theString = $theString . (' -v' x $theBuildObject->verboseFlag()) if $theBuildObject->verboseFlag() ;

    $theBuildObject->run($theString) ;

    return $theObject ;
} ;

sub validate
{
    #
    # A valid lilo.conf has a default entry and a valid stanza
    # at that entry.
    #

    my $theObject = shift ;

    my $theBuildObject = shift ;

    $theObject->SUPER::validate($theBuildObject) ;

    my $theFileName = $theObject->filename() ;

    my $theLiloFile = new StanzaFile::Lilo(file_name=>$theFileName) ;
    my $theIndex ;

    if (!(defined($theIndex = $theLiloFile->header()->item('default'))))
    {
	print STDERR <<"EOT" ;

$theFileName must be in a standard form for kif to work properly.
There must be a default entry in the header portion of the file
of the form:

default=label

where label is the value of the label item in the stanza to be
booted by default.

Please add an appropriate line to $theFileName and rerun kif.
EOT
        croak "$theFileName is invalid." ;
    } ;

    #
    # Now make sure that the particular configuration is actually
    # in the configuration file.
    #

    my $theDefaultStanza ;

    foreach ($theLiloFile->order())
    {
	if ($theLiloFile->stanza($_)->item('label') eq $theLiloFile->header()->item('default'))
	{
	    $theDefaultStanza = $theLiloFile->stanza($_) ;
	    last ;
	} ;
    } ;

    if (!(defined($theDefaultStanza)))
    {
	print STDERR << "EOT" ;
The stanza indicated by the default header item in $theFileName does 
not exist.  You must correct the default value and rerun kif.
EOT
        croak "Invalid default configuration header in $theFileName" ;
    } ;
} ;

1;
