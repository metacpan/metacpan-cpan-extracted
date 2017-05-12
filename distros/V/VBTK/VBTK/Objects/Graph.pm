#! /bin/perl
#############################################################################
#
#                 NOTE: This file under revision control using RCS
#                       Any changes made without RCS will be lost
#
#              $Source: /usr/local/cvsroot/vbtk/VBTK/Objects/Graph.pm,v $
#            $Revision: 1.6 $
#                $Date: 2002/03/04 20:53:07 $
#              $Author: bhenry $
#              $Locker:  $
#               $State: Exp $
#
#              Purpose: A perl library used to store VB Object Graph Groupings
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
#       $Log: Graph.pm,v $
#       Revision 1.6  2002/03/04 20:53:07  bhenry
#       *** empty log message ***
#
#       Revision 1.5  2002/03/04 16:49:10  bhenry
#       Changed requirement back to perl 5.6.0
#
#       Revision 1.4  2002/03/02 00:53:55  bhenry
#       Documentation updates
#
#       Revision 1.3  2002/01/28 18:46:48  bhenry
#       Removed reference to VBTK::Serialize
#
#       Revision 1.2  2002/01/21 17:07:50  bhenry
#       Disabled 'uninitialized' warnings
#
#       Revision 1.1.1.1  2002/01/17 18:05:57  bhenry
#       VBTK Project
#

package VBTK::Objects::Graph;

use 5.6.0;
use strict;
use warnings;
# I like using undef as a value so I'm turning off the uninitialized warnings
no warnings qw(uninitialized);

use VBTK::Common;
use VBTK::File;
use VBTK::Client;
use URI::Escape;

our $VERBOSE=$ENV{'VERBOSE'};

# Define a list of abbreviation which can be used for the member parms.  These
# will be used mostly when passing parm values through html.
our %ABBREV = (
    DataSourceList => 'dsl',
    Labels         => 'l',
    LineWidth      => 'lw',
    Colors         => 'c',
    CF             => 'cf',
    VLabel         => 'vl',
    Title          => 't',
    TimeWindow     => 'tw',
    XSize          => 'xs',
    YSize          => 'ys' );

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

    log("Setting up Graph") if ($VERBOSE > 1);

    $self->set(@_);

    my($parmHash,$parm);

    # If the 'Parms' parameter was passed, then search through it for any of the
    # abbreviated parms defined in the %ABBREV hash and if any are found, then use
    # them to set the associated member parms.
    if ($self->{Parms} ne undef)
    {
        my $parmHash = $self->{Parms};
        foreach $parm (keys %ABBREV)
        {
            $self->{$parm} = $parmHash->{$ABBREV{$parm}} || $parmHash->{$parm}
                if ($self->{$parm} eq undef);
        }
        delete($self->{Parms});
    }

    # Setup a hash of default parameters
    my $defaultParms = {
        DataSourceList => undef,
        Labels         => $::REQUIRED,
        LineWidth      => undef,
        Colors         => undef,
        CF             => undef,
        VLabel         => undef,
        Title          => undef,
        TimeWindow     => undef,
        XSize          => undef,
        YSize          => undef,
        Target         => undef
    };

    # Run a validation on the passed parms, using the default parms        
    $self->validateParms($defaultParms) || return undef;

    ($self);
}

#-------------------------------------------------------------------------------
# Function:     generateUrlParms
# Description:  Generate the URL parameters which will cause the Rrd.pm library to
#               generate the appropriate graphs for this graph object
# Input Parms:  Parms ptr
# Output Parms: Array of URL parms
#-------------------------------------------------------------------------------
sub generateUrlParms
{ 
    my $self = shift;
    my ($_parms) = shift;
    my $Target = $self->{Target};

    my ($parm,$abbrev,$targetVal,$imgVal,@imgUrlParms,@targetUrlParms,$val);

    # Step through each parm,abbreviation pair, setting the values in the
    # currParms hash appropriately.  Try the parms hash first (both abbreviated
    # and full names), then try the object itself.
    while(($parm,$abbrev) = each(%ABBREV))
    {
        $val = $_parms->{$abbrev} || $_parms->{$parm};
        $imgVal = $val || $self->{$parm};

        # If there's a value to pass, then encode it and add it to the list
        if ($imgVal ne undef)
        {
            $imgVal = &uriEscape($imgVal);
            push(@imgUrlParms,"$abbrev=$imgVal");
        }

        # Now form the url pairs for the Target URL.  If no 'VBObjName' parm
        # is specified in the Target hash, then set all URL pairs just like
        # for the image URL.
        if($Target->{VBObjName} eq undef)
        {
            $targetVal = $val || $Target->{$parm} || $self->{$parm};

            if($targetVal ne undef)
            {
                $targetVal = &uriEscape($targetVal);
                push(@targetUrlParms,"$abbrev=$targetVal");
            }
        }
        # If the 'VBObjName' was specified, then ignore any parms passed in
        # only set URL pairs for parms actually specified in the Target hash.
        elsif($Target->{$parm} ne undef)
        {
            $targetVal = &uriEscape($Target->{$parm});
            push(@targetUrlParms,"$abbrev=$targetVal");
        }
    }

    # If the VBObjName parm is specified in the Target hash, then add in the URL
    # pairs for the VBObjName and GroupNumber.
    if($Target->{VBObjName} ne undef)
    {
        $Target->{GroupNumber} = 1 if ($Target->{GroupNumber} < 1);
        push(@targetUrlParms,"name=$Target->{VBObjName}","groupNumber=$Target->{GroupNumber}");
    }

    (join('&',@imgUrlParms),join('&',@targetUrlParms));
}

#-------------------------------------------------------------------------------
# Function:     uriEscape
# Description:  Escape out all non alpha-numeric characters in preparation for 
#               transmission over a HTTP request
# Input Parms:  String
# Output Parms: Escaped String
#-------------------------------------------------------------------------------
sub uriEscape
{
    my ($var) = @_;

    # Escape out any unsafe characters in the text
    my $safeVar = uri_escape($var,"^A-Za-z0-9-_");

    ($safeVar);
}

# Simple Get Methods
sub getTimeWindow     { $_[0]->{TimeWindow}; }
sub getDataSourceList { $_[0]->{DataSourceList}; }
sub getLabels         { $_[0]->{Labels}; }
sub getLineWidth      { $_[0]->{LineWidth}; }
sub getColors         { $_[0]->{Colors}; }
sub getCF             { $_[0]->{CF}; }
sub getVLabel         { $_[0]->{VLabel}; }
sub getTitle          { $_[0]->{Title}; }
sub getXSize          { $_[0]->{XSize}; }
sub getYSize          { $_[0]->{YSize}; }
sub getTarget         { $_[0]->{Target}; }

1;
__END__

=head1 NAME

VBTK::Objects::Graph - Internal module of VBTK

=head1 SYNOPSIS

    To come...

=head1 DESCRIPTION

This is an internal module of the VB tool kit used to handle the definition
of graphs.  Do not try to access this package directly.

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
