#! /bin/perl
#############################################################################
#
#                 NOTE: This file under revision control using RCS
#                       Any changes made without RCS will be lost
#
#              $Source: /usr/local/cvsroot/vbtk/VBTK/Objects/History.pm,v $
#            $Revision: 1.8 $
#                $Date: 2002/03/04 20:53:07 $
#              $Author: bhenry $
#              $Locker:  $
#               $State: Exp $
#
#              Purpose: A perl library used to store VB Object history
#                       elements
#
#       Copyright (C) 1996 - 2002  Brent Henry
#
#       This program is free software; you can redistribute it and/or
#       modify it under the terms of version 2 of the GNU General Public
#       License as published by the Free Software Foundation available at:
#       http://http://www.gnu.org/copyleft/gpl.html
#
#       This program is distributed in the hope that it will be useful,
#       but WITHOUT ANY WARRANTY; without even the implied warranty of
#       MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#       GNU General Public License for more details.
#
#############################################################################
#
#
#       REVISION HISTORY:
#
#       $Log: History.pm,v $
#       Revision 1.8  2002/03/04 20:53:07  bhenry
#       *** empty log message ***
#
#       Revision 1.7  2002/03/04 16:49:10  bhenry
#       Changed requirement back to perl 5.6.0
#
#       Revision 1.6  2002/03/02 00:53:55  bhenry
#       Documentation updates
#
#       Revision 1.5  2002/02/20 19:25:18  bhenry
#       *** empty log message ***
#
#       Revision 1.4  2002/01/25 16:42:06  bhenry
#       Changed to serialized filename to end in '.ser'
#
#       Revision 1.3  2002/01/25 07:13:08  bhenry
#       Changed to use Storable instead of VBTK::Serialize
#
#       Revision 1.2  2002/01/21 17:07:50  bhenry
#       Disabled 'uninitialized' warnings
#
#       Revision 1.1.1.1  2002/01/17 18:05:57  bhenry
#       VBTK Project
#

package VBTK::Objects::History;

use 5.6.0;
use strict;
use warnings;
# I like using undef as a value so I'm turning off the uninitialized warnings
no warnings qw(uninitialized);

use VBTK::Common;
use VBTK::File;

our $VERBOSE=$ENV{'VERBOSE'};
our $FULL=3;
our $NOTEXT=2;
our $MINIMAL=1;

our %CACHE_LEVELS = (
    Text          => $FULL,
    HeaderMsg     => $FULL,
    FooterMsg     => $FULL,
    Status        => $NOTEXT,
    Timestamp     => $NOTEXT,
    Repeated      => $NOTEXT,
    RepeatStart   => $NOTEXT,
    RawStatus     => $NOTEXT,
    ExpireTime    => $NOTEXT,
);

#-------------------------------------------------------------------------------
# Function:     new
# Description:  Object constructor.  Allocates memory for all class members
# Input Parms:  Configuration filename
# Output Parms: Pointer to class
#-------------------------------------------------------------------------------
sub new
{
    my $type = shift;
    my $self = {};
    bless $self, $type;

    $self->set(@_);

    log("Setting up VB History Object for $self->{ObjName}, $self->{Timestamp}")
        if ($VERBOSE > 3);

    # Only run this part if we're in VERBOSE mode, it's not really necessary, but
    # is just an extra check to make sure the right parameters are being passed.
    if ($VERBOSE)
    {
        # Setup a hash of default parameters
        my $defaultParms = {
            ObjPath         => $::REQUIRED,
            ObjName         => $::REQUIRED,
            FileName        => $::REQUIRED,
            Timestamp       => undef,
            Status          => undef,
            Text            => undef,
            HeaderMsg       => undef,
            FooterMsg       => undef,
            Repeated        => undef,
            RepeatStart     => undef,
            RawStatus       => undef,
            ExpireTime      => undef,
            CacheMode       => undef,
        };

        # Run a validation on the passed parms, using the default parms        
        $self->validateParms($defaultParms) || return undef;
    }

    my $ObjPath   = $self->{ObjPath};
    my $ObjName   = $self->{ObjName};
    my $FileName  = $self->{FileName};
    my $metaFileName = "$ObjPath/$ObjName/$FileName.ser";

    $self->{CacheMode} = $NOTEXT unless ($self->{CacheMode});
    $self->{metaFileObj} = new VBTK::File($metaFileName);

    # Mark the object as only currently having the minimal data loaded.    
    $self->{currCacheMode} = $MINIMAL;

    # If no status was passed, then try to load the object from the corresponding
    # history file.  Pass in the specified cacheMode.
    if($self->{Status} eq undef)
    {
        $self->load($self->{CacheMode}) || return undef;
    }

    ($self);
}

#-------------------------------------------------------------------------------
# Function:     load
# Description:  Load the history object from it's file.
# Input Parms:  None
# Output Parms: None
#-------------------------------------------------------------------------------
sub load
{
    my $self = shift;
    my $cacheMode = shift;

    # If we're already loaded at a higher cache mode than is requested, then just
    # return.
    return 1 if ($self->{currCacheMode} >= $cacheMode);
    
    my $ObjName     = $self->{ObjName};
    my $FileName    = $self->{FileName};
    my $metaFileObj = $self->{metaFileObj};
    my ($key);

    &log("Loading history object for '$ObjName - $FileName', cacheMode $cacheMode")
        if ($VERBOSE > 1);
    my $struct = $metaFileObj->serGet();

    return undef if ($struct eq undef);

    # Load retrieved values into the current object, but only those which 
    # correspond to the specified cache level.
    foreach $key (keys %{$struct})
    {
        if ($CACHE_LEVELS{$key} <= $cacheMode)
        {
            &log("Loading '$key'") if ($VERBOSE > 2);
            $self->{$key} = $struct->{$key};
        }
    }

    # Mark as loaded.
    $self->{currCacheMode} = $cacheMode;

    (1);        
}

#-------------------------------------------------------------------------------
# Function:     store
# Description:  Write the history object out to a file
# Input Parms:  
# Output Parms: 
#-------------------------------------------------------------------------------
sub store
{
    my $self = shift;
    my $ObjName   = $self->{ObjName};
    my $Timestamp = $self->{Timestamp};
    my $CacheMode = $self->{CacheMode};
    my $metaFileObj = $self->{metaFileObj};
    my ($key);

    # Create a structure of the data elements we want to save
    my $struct = { map { $_ => $self->{$_} } keys %CACHE_LEVELS };

    &log("Saving history object for '$ObjName - $Timestamp'") if ($VERBOSE > 1);
    $metaFileObj->serPut($struct) || return undef;

    # Now remove any entries from the object which should not be cached in memory.
    foreach $key (keys %CACHE_LEVELS)
    {
        delete($self->{$key}) if ($CACHE_LEVELS{$key} > $CacheMode);
    }

    # Re-set the current cache mode value    
    $self->{currCacheMode} = $CacheMode;
    
    (1);
}

#-------------------------------------------------------------------------------
# Function:     delete
# Description:  Delete the history object
# Input Parms:  
# Output Parms: 
#-------------------------------------------------------------------------------
sub delete
{
    my $self = shift;
    $self->{metaFileObj}->unlink;

    (1);
}

#-------------------------------------------------------------------------------
# Function:     loadAndGet
# Description:  Load the specified parm from it's meta file if it's not already
#               loaded, and then return it's value.
# Input Parms:  Parm name.
# Output Parms: Value
#-------------------------------------------------------------------------------
sub loadAndGet
{
    my $self = shift;
    my $parm = shift;
    
    # If the value is already loaded, then just return it.
    return $self->{$parm} if ($self->{$parm});
    
    $self->load($CACHE_LEVELS{$parm});
    
    $self->{$parm};
}

# Simple Get Methods
sub getTimestamp    { $_[0]->loadAndGet('Timestamp'); }
sub getFileName     { $_[0]->{FileName}; }
sub getStatus       { $_[0]->loadAndGet('Status'); }
sub getHeaderMsg    { $_[0]->loadAndGet('HeaderMsg'); }
sub getFooterMsg    { $_[0]->loadAndGet('FooterMsg'); }
sub getRepeated     { $_[0]->loadAndGet('Repeated'); }
sub getRepeatStart  { $_[0]->loadAndGet('RepeatStart'); }
sub getRawStatus    { $_[0]->loadAndGet('RawStatus'); }
sub getExpireTime   { $_[0]->loadAndGet('ExpireTime'); }
sub getText         { $_[0]->loadAndGet('Text'); }

# Simple Set and Comparison Methods
sub setRepeatStart  { $_[0]->{RepeatStart} = $_[1]; }
sub setStatus       { $_[0]->{Status} = $_[1]; }

sub addToRepeated   { $_[0]->{Repeated} += $_[1]; }
sub addHeaderMsg    { $_[0]->{HeaderMsg} = $_[1] . $_[0]->{HeaderMsg}; }
sub addFooterMsg    { $_[0]->{FooterMsg} .= $_[1]; }

sub sameStatus      { $_[0]->{Status} eq $_[1]->{Status}; }

1;
__END__

=head1 NAME

VBTK::Objects::History - Internal module of VBTK

=head1 SYNOPSIS

    To come...

=head1 DESCRIPTION

This is an internal module of the VB tool kit used to handle object history.
Do not try to access this package directly.

=head1 SEE ALSO

=over 4

=item L<VBTK|VBTK>

=item L<VBTK::Objects|VBTK::Objects>

=item L<VBTK::Server|VBTK::Server>

=back

=head1 AUTHOR

Brent Henry, vbtoolkit@yahoo.com

=head1 COPYRIGHT

Copyright (C) 1996-2002 Brent Henry

This program is free software; you can redistribute it and/or
modify it under the terms of version 2 of the GNU General Public
License as published by the Free Software Foundation available at:
http://www.gnu.org/copyleft/gpl.html

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

=cut
