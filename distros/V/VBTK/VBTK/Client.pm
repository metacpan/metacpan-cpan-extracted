#! /bin/perl
#############################################################################
#
#                 NOTE: This file under revision control using RCS
#                       Any changes made without RCS will be lost
#
#              $Source: /usr/local/cvsroot/vbtk/VBTK/Client.pm,v $
#            $Revision: 1.9 $
#                $Date: 2002/03/04 20:53:06 $
#              $Author: bhenry $
#              $Locker:  $
#               $State: Exp $
#
#              Purpose: A common perl library used to simplify communication between
#                   the vbserver process and it's various client processes.
#
#       Copyright (C) 1996 - 2002  Brent Henry
#
#       This program is free software; you can redistribute it and/or
#       modify it under the terms of version 2 of the GNU General Public
#       License as published by the Free Software Foundation available at:
#       http://www.gnu.org/copyleft/gpl.html
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
#       $Log: Client.pm,v $
#       Revision 1.9  2002/03/04 20:53:06  bhenry
#       *** empty log message ***
#
#       Revision 1.8  2002/03/04 16:49:08  bhenry
#       Changed requirement back to perl 5.6.0
#
#       Revision 1.7  2002/03/02 00:53:54  bhenry
#       Documentation updates
#
#       Revision 1.6  2002/02/08 02:16:04  bhenry
#       *** empty log message ***
#

package VBTK::Client;

use 5.6.0;
use strict;
use warnings;
# I like using undef as a value so I'm turning off the uninitialized warnings
no warnings qw(uninitialized);

use VBTK::Common;
use LWP::UserAgent;
use URI::Escape;
use Storable qw(freeze thaw);

our $VERSION = '0.01';

our $VERBOSE = $ENV{VERBOSE};
our $SEND_TIMEOUT = 30;
our $RELAY_TIMEOUT = 10;

#-------------------------------------------------------------------------------
# Function:     new
# Description:  Object constructor.  Allocates memory for all class members
# Input Parms:
# Output Parms: Pointer to class
#-------------------------------------------------------------------------------
sub new
{
    my $type = shift;
    my $self = {};
    bless $self, $type;

    $self->set(@_);

    $self->{RemoteURI} = $::VBURI if (! defined $self->{RemoteURI});

    my $ua = new LWP::UserAgent;
    $ua->agent("VBTK " . $ua->agent);
    $ua->timeout($SEND_TIMEOUT);

    $self->{ua} = $ua;

    ($self);
}

#-------------------------------------------------------------------------------
# Function:     setStatus
# Description:  Set the status of an object on a vbserver, if any value is
#               passed to the 4th argument, then all messages will be suppressed.
# Input Parms:  Object Name, Status, Text Message
# Output Parms: Return code
#-------------------------------------------------------------------------------
sub setStatus
{
    my $obj = shift;
    my $ua = $obj->{ua};
    my $RemoteURI = $obj->{RemoteURI};
    my %args = @_;
    my (@content,$key,$value,$safeValue);

    &log("Sending status to '$RemoteURI'") if ($VERBOSE > 1);

    while(($key,$value) = each %args)
    {
        $safeValue = &uriEscape($value);
        push(@content,"$key=$safeValue");
    }

    # Create a request
    my $req = new HTTP::Request POST => "$RemoteURI/setStatusRaw.phtml";
    $req->content_type('application/x-www-form-urlencoded');
    $req->content( join('&',@content) );

    # Pass request to the user agent and get a response back
    my $res = $ua->request($req);

    # Check the reply
    if((! $res->is_success)||($res->content !~ /OK/))
    {
        &error("Bad result from vbserver - " . $res->content);
        return -1;
    }

    (0);
}

#-------------------------------------------------------------------------------
# Function:     setBaseline
# Description:  Set the baseline text of an object on a vbserver
# Input Parms:  Object Name, Baseline Text
# Output Parms: Return code
#-------------------------------------------------------------------------------
sub setBaseline
{
    my $obj = shift;
    my $ua = $obj->{ua};
    my $RemoteURI = $obj->{RemoteURI};
    my %args = @_;
    my (@content,$key,$value,$safeValue);

    &log("Sending baseline to '$RemoteURI'") if ($VERBOSE > 1);

    while(($key,$value) = each %args)
    {
        $safeValue = &uriEscape($value);
        push(@content,"$key=$safeValue");
    }

    # Create a request
    my $req = new HTTP::Request POST => "$RemoteURI/setBaselineRaw.phtml";
    $req->content_type('application/x-www-form-urlencoded');
    $req->content( join('&',@content) );

    # Pass request to the user agent and get a response back
    my $res = $ua->request($req);

    # Check the reply
    if((! $res->is_success)||($res->content !~ /OK/))
    {
        &error("Bad result from vbserver - " . $res->content);
        return undef;
    }

    (1);
}

#-------------------------------------------------------------------------------
# Function:     getStatus
# Description:  Retrieve the status of an object
# Input Parms:  Object Name
# Output Parms: Result Status
#-------------------------------------------------------------------------------
sub getStatus
{
    my $obj = shift;
    my $ua = $obj->{ua};
    my $RemoteURI = $obj->{RemoteURI};

    my ($name) = @_;

    &log("Retrieving status for '$name'") if ($VERBOSE > 1);

    # Create a request
    my $req = new HTTP::Request GET => "$RemoteURI/getStatusRaw.phtml?name=$name";
    $req->content_type('application/x-www-form-urlencoded');

    # Pass request to the user agent and get a response back
    my $res = $ua->request($req);

    # Check the reply
    if(! $res->is_success)
    {
        return -1;
    }

    # Return the resulting text
    ($res->content);
}

#-------------------------------------------------------------------------------
# Function:     getGraphDbLastTimestamp
# Description:  Retrieve the last timestamp in the graphdb for this object.
# Input Parms:  Object Name
# Output Parms: Timestamp or Undef if object does not exist
#-------------------------------------------------------------------------------
sub getGraphDbLastTimestamp
{
    my $obj = shift;
    my $ua = $obj->{ua};
    my $RemoteURI = $obj->{RemoteURI};

    my ($name) = @_;

    # Create a request
    my $req = new HTTP::Request GET => "$RemoteURI/getGraphDbLastTimestamp.phtml?name=$name";
    $req->content_type('application/x-www-form-urlencoded');

    # Pass request to the user agent and get a response back
    my $res = $ua->request($req);

    # Check the reply
    if(! $res->is_success)
    {
        return undef;
    }

    # Return the resulting text
    ($res->content);
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
    my $safeVar = uri_escape($var,"^A-Za-z0-9\-_.!~*'()");

    ($safeVar);
}

#-------------------------------------------------------------------------------
# Function:     getUrl
# Description:  Access the specified URL and retrieve the html
# Input Parms:  URL
# Output Parms: Resulting HTML
#-------------------------------------------------------------------------------
sub getUrl
{
    my $url = shift;

    my $ua = new LWP::UserAgent;
    $ua->agent("VBTK " . $ua->agent);
    $ua->timeout($RELAY_TIMEOUT);

    &log("Retrieving URL '$url'") if ($VERBOSE > 1);

    # Create a request and submit it
    my $req = new HTTP::Request GET => "$url";
    $req->content_type('application/x-www-form-urlencoded');

    my $res = $ua->request($req);

    # Check the reply
    if(! $res->is_success)
    {
        return undef;
    }

    my $content = $res->content;
    return undef if ($content =~ /^\s*$/);

    # Return the resulting text
    ($res->content);
}

#-------------------------------------------------------------------------------
# Function:     getBaseline
# Description:  Retrieve the baseline text for the specified object.
# Input Parms:  VBObjName
# Output Parms: Baseline Text
#-------------------------------------------------------------------------------
sub getBaseline
{
    my $obj = shift;
    my $ua = $obj->{ua};
    my $RemoteURI = $obj->{RemoteURI};

    my ($name) = @_;

    # Create a request
    my $req = new HTTP::Request GET => "$RemoteURI/getBaselineRaw.phtml?name=$name";
    $req->content_type('application/x-www-form-urlencoded');

    # Pass request to the user agent and get a response back
    my $res = $ua->request($req);

    # Check the reply
    if(! $res->is_success)
    {
        return undef;
    }

    # Return the resulting text
    ($res->content);
}

#-------------------------------------------------------------------------------
# Function:     getSyncFileObj
# Description:  Retrieve a file object from the server, which will be used to 
#               sync the corresponding file on the client side
# Input Parms:  fileName
# Output Parms: File Object
#-------------------------------------------------------------------------------
sub getSyncFileObj
{
    my $obj = shift;
    my $ua = $obj->{ua};
    my $RemoteURI = $obj->{RemoteURI};

    my ($fileName) = @_;

    # Create a request
    my $req = new HTTP::Request GET => "$RemoteURI/getSyncFileObj.phtml?fileName=$fileName";
    $req->content_type('application/x-www-form-urlencoded');

    # Pass request to the user agent and get a response back
    my $res = $ua->request($req);

    # Check the reply
    if(! $res->is_success)
    {
        return undef;
    }

    my $result = $res->content || return undef;
    
    my $fileObj = &thaw($result);
    
    ($fileObj);
}

#-------------------------------------------------------------------------------
# Function:     getSyncList
# Description:  Retrieve a list of file objects which are in the sync list
# Input Parms:  None
# Output Parms: File Object Sync List
#-------------------------------------------------------------------------------
sub getSyncList
{
    my $obj = shift;
    my $ua = $obj->{ua};
    my $RemoteURI = $obj->{RemoteURI};

    # Create a request
    my $req = new HTTP::Request GET => "$RemoteURI/getSyncList.phtml";
    $req->content_type('application/x-www-form-urlencoded');

    # Pass request to the user agent and get a response back
    my $res = $ua->request($req);

    # Check the reply
    if(! $res->is_success)
    {
        return undef;
    }

    my $result = $res->content || return undef;
    my $struct = &thaw($result) || return undef;

    # Return an array containing file objects to be synced.  The first element
    # of the array is the value of VBHOME on the remote server.
    @{$struct}; 
}

1;
__END__

=head1 NAME

VBTK::Client - Internal module of VBTK

=head1 SYNOPSIS

    To come...

=head1 DESCRIPTION

This is an internal module of the VB tool kit used in the client processes
to handle the network with the VBServer.  Do not try to access this package
directly.

=head1 SEE ALSO

=over 4

=item L<VBTK|VBTK>

=item L<VBTK::Parser|VBTK::Parser>

=item L<VBTK::ClientObject|VBTK::ClientObject>

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
