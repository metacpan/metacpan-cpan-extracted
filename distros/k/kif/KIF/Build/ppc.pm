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
#       Isolate kif related classes in a KIF namespace.
#

package KIF::Build::ppc ;

use vars qw($VERSION @ISA) ;

our $VERSION = "1.03" ;

use strict ;

use Carp ;
use File::Copy ;
use KIF::Build ;
use KIF::Bootloader ;

our @ISA = qw(KIF::Build) ;

sub new
{
    my $thePackage = shift ;

    my $theObject = $thePackage->SUPER::new(@_) ;

    $theObject->bootloader(new KIF::Bootloader) ;

    return $theObject ;
} ;

sub validate
{
    my $theObject = shift ;

    croak '/boot/vmlinux must exist.' if (!-e '/boot/vmlinux') ;
    
    croak '/boot/vmlinux must be a link.' if (!-l '/boot/vmlinux') ;

    $theObject->SUPER::validate() ;
} ;

sub doBootloader
{
    my $theObject = shift ;
    my $theReleaseTag = $theObject->releaseTag() ;

    $theObject->run('echo \'Copy /boot/vmlinux-$theReleaseTag to the Mac OS for use by BootX\'') ;
} ;

1;
