#!/usr/bin/perl
#
# Revision History:
#
#   26-Nov-2002 Dick Munroe (munroe@csworks.com)
#       Initial Version Created.
#
#   03-Dec-2002 Dick Munroe (munroe@csworks.com)
#       Add an allocate only method, _new, which will, if
#       necessary, clone an object.
#       Add a _clone interface.
#
#   18-May-2003 Dick Munroe (munroe@csworks.com)
#       Make sure package variables don't leak.
#
#   19-May-2003 Dick Munroe (munroe@csworks.com)
#       Use Carp.
#       Isolate kif related classes in a KIF namespace.
#

package KIF::Bootloader ;

use vars qw($VERSION @ISA) ;

our $VERSION = "1.03" ;
our @ISA = qw(
	      ) ;

use strict ;

use Carp ;
use FileHandle ;

sub _clone
{
    my ($theObject, $theSource) = @_ ;

    foreach (keys %{$theSource})
    {
	$theObject->{$_} = $theSource->{$_} ;
    } ;

    return $theObject ;
} ;

sub _new
{
    my $thePackage = shift ;

    my $theClass = ref($thePackage) || $thePackage ;
    my $theParent = ref($thePackage) && $thePackage ;

    my $theObject = bless
    {
	'filename' => undef
    }, $theClass ;

    if ($theParent)
    {
	$theObject->_clone($theParent) ;
    } ;

    return $theObject ;
} ;

sub new
{
    my $thePackage = shift ;

    return $thePackage->_new() ;
} ;

sub _file
{

    my $theObject = shift ;
    my $theFileName = shift ;

    #
    # Read a file and return the contents as a string.
    #

    my $theFileHandle = new FileHandle "< $theFileName" or croak "Can't open $theFileName" ;

    return eval { my @theFile = $theFileHandle->getlines ; join '',@theFile } ;
} ;

sub filename
{
    my $theObject = shift ;

    $theObject->{'filename'} = $_[0] if (@_) ;

    return $theObject->{'filename'} ;
} ;

sub initrdFile
{
    return undef ;
} ;

sub modify
{
} ;

sub validate
{
} ;

1;
