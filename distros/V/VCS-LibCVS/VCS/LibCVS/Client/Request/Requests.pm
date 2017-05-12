#
# Copyright (c) 2003,2004,2005 Alexander Taler (dissent@0--0.org)
#
# All rights reserved. This program is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.
#

use strict;

=head1 NAME

VCS::LibCVS::Client::Request::Requests - Classes for many requests

=head1 SYNOPSIS

  my $mode = VCS::LibCVS::Datum::Mode->new("u=rw,g=rw,o=r");
  my $mod_request = VCS::LibCVS::Client::Request::Modified->
                              new( [ "afile" , $mode, "/tmp/afile" ] );
  $client->submit_request($mod_request);

=head1 DESCRIPTION

Each request of the CVS client protocol has its own class.  Many of them are
here.

Each request requires specific pieces of data; this data is listed by type and
name for each request.

=head1 SUPERCLASS

  VCS::LibCVS::Client::Request

=cut

$VCS::LibCVS::Client::Request::Requests::REVISION = '$Header: /cvsroot/libcvs-perl/libcvs-perl/VCS/LibCVS/Client/Request/Requests.pm,v 1.23 2005/10/10 12:52:11 dissent Exp $ ';

###############################################################################
# Root
###############################################################################

=head1 CLASSES

=head2 VCS::LibCVS::Client::Request::Root

Specify the CVS root directory for this session.  This request is issued
automatically by the Client.

  "String": RootDir

=cut

package VCS::LibCVS::Client::Request::Root;
use vars ('@ISA');
@ISA =("VCS::LibCVS::Client::Request");
sub BEGIN { push @VCS::LibCVS::Client::Request::Valid_requests, "Root"; }

###############################################################################
# Valid-responses
###############################################################################

=head2 VCS::LibCVS::Client::Request::Valid_responses

  "String": List of valid responses

=cut

package VCS::LibCVS::Client::Request::Valid_responses;
use vars ('@ISA');
@ISA =("VCS::LibCVS::Client::Request");
sub BEGIN { push @VCS::LibCVS::Client::Request::Valid_requests, "Valid-responses"; }

###############################################################################
# valid-requests
###############################################################################

=head2 VCS::LibCVS::Client::Request::valid_requests

Ask the server for a list of requests it accepts.  This request is issued
automatically by the Client, who provides a way to access them.

No data is required.

=cut

package VCS::LibCVS::Client::Request::valid_requests;
use vars ('@ISA');
@ISA =("VCS::LibCVS::Client::Request");
sub BEGIN { push @VCS::LibCVS::Client::Request::Valid_requests, "valid-requests"; }
sub required_data { return (); }

###############################################################################
# Directory
###############################################################################

=head2 VCS::LibCVS::Client::Request::Directory

Specify a directory which the next Argument Using Request will work in.

  "DirectoryName": Local Directory
  "DirectoryName": Absolute Repository Directory

=cut

package VCS::LibCVS::Client::Request::Directory;
use vars ('@ISA');
@ISA =("VCS::LibCVS::Client::Request");
sub BEGIN { push @VCS::LibCVS::Client::Request::Valid_requests, "Directory"; }
sub required_data { return ("DirectoryName", "DirectoryName"); }

###############################################################################
# Sticky
###############################################################################

=head2 VCS::LibCVS::Client::Request::Sticky

Specify that the most recent directory provided has a sticky tag.

  "TagSpec": the sticky tag

=cut

package VCS::LibCVS::Client::Request::Sticky;
use vars ('@ISA');
@ISA =("VCS::LibCVS::Client::Request");
sub BEGIN { push @VCS::LibCVS::Client::Request::Valid_requests, "Sticky"; }
sub required_data { return ("TagSpec"); }

###############################################################################
# Entry
###############################################################################

=head2 VCS::LibCVS::Client::Request::Entry

Specify an RCS style Entry Line for the next Modifed request.

  "Entry": The entry line

=cut

package VCS::LibCVS::Client::Request::Entry;
use vars ('@ISA');
@ISA =("VCS::LibCVS::Client::Request");
sub BEGIN { push @VCS::LibCVS::Client::Request::Valid_requests, "Entry"; }
sub required_data { return ("Entry"); }

###############################################################################
# Checkin-time
###############################################################################

=head2 VCS::LibCVS::Client::Request::Checkin_time

Specify the checkin time for the next Modifed request.

  "Time": The checkin time

=cut

package VCS::LibCVS::Client::Request::Checkin_time;
use vars ('@ISA');
@ISA =("VCS::LibCVS::Client::Request");
sub BEGIN { push @VCS::LibCVS::Client::Request::Valid_requests, "Checkin-time"; }
sub required_data { return ("Time"); }

###############################################################################
# Modified
###############################################################################

=head2 VCS::LibCVS::Client::Request::Modified

Specify the contents of a modified file.

  "FileName": the name of the modified file
  "FileMode": its mode
  "FileContents": the file itself

=cut

package VCS::LibCVS::Client::Request::Modified;
use vars ('@ISA');
@ISA =("VCS::LibCVS::Client::Request");
sub BEGIN { push @VCS::LibCVS::Client::Request::Valid_requests, "Modified"; }
sub required_data { return ("FileName", "FileMode", "FileContents"); }

###############################################################################
# Is-modified
###############################################################################

=head2 VCS::LibCVS::Client::Request::Is_modified

Specify that a file is modified without sending its contents.

  "FileName": Name of the modified file

=cut

package VCS::LibCVS::Client::Request::Is_modified;
use vars ('@ISA');
@ISA =("VCS::LibCVS::Client::Request");
sub BEGIN { push @VCS::LibCVS::Client::Request::Valid_requests, "Is-modified"; }
sub required_data { return ("FileName"); }

###############################################################################
# Unchanged
###############################################################################

=head2 VCS::LibCVS::Client::Request::Unchanged

Specify that a file has not been modified.

  "FileName": Name of the unmodified file

=cut

package VCS::LibCVS::Client::Request::Unchanged;
use vars ('@ISA');
@ISA =("VCS::LibCVS::Client::Request");
sub BEGIN { push @VCS::LibCVS::Client::Request::Valid_requests, "Unchanged"; }
sub required_data { return ("FileName"); }

###############################################################################
# UseUnchanged
###############################################################################

=head2 VCS::LibCVS::Client::Request::UseUnchanged

Specify the version of the protocol

No data is required.

=cut

package VCS::LibCVS::Client::Request::UseUnchanged;
use vars ('@ISA');
@ISA =("VCS::LibCVS::Client::Request");
sub BEGIN { push @VCS::LibCVS::Client::Request::Valid_requests, "UseUnchanged"; }
sub required_data { return (); }

###############################################################################
# Questionable
###############################################################################

=head2 VCS::LibCVS::Client::Request::Questionable

Specify the name of a file which may need to be ignored

  "FileName": Name of the unmodified file

=cut

package VCS::LibCVS::Client::Request::Questionable;
use vars ('@ISA');
@ISA =("VCS::LibCVS::Client::Request");
sub BEGIN { push @VCS::LibCVS::Client::Request::Valid_requests, "Questionable"; }
sub required_data { return ("FileName"); }

###############################################################################
# Case
###############################################################################

=head2 VCS::LibCVS::Client::Request::Case

Specify that the server should ignore case

No data is required.

=cut

package VCS::LibCVS::Client::Request::Case;
use vars ('@ISA');
@ISA =("VCS::LibCVS::Client::Request");
sub BEGIN { push @VCS::LibCVS::Client::Request::Valid_requests, "Case"; }
sub required_data { return (); }

###############################################################################
# init
###############################################################################

=head2 VCS::LibCVS::Client::Request::init

Initialize a new repository.  No need to call Root beforehand.

  "String": RootName of repository to be initialized.

=cut

package VCS::LibCVS::Client::Request::init;
use vars ('@ISA');
@ISA =("VCS::LibCVS::Client::Request");
sub BEGIN { push @VCS::LibCVS::Client::Request::Valid_requests, "init"; }

###############################################################################
# noop
###############################################################################

=head2 VCS::LibCVS::Client::Request::noop

No operation.  Do nothing except get pent up responses from the server

No data is required.

=cut

package VCS::LibCVS::Client::Request::noop;
use vars ('@ISA');
@ISA =("VCS::LibCVS::Client::Request");
sub BEGIN { push @VCS::LibCVS::Client::Request::Valid_requests, "noop"; }
sub required_data { return (); }

###############################################################################
# version
###############################################################################

=head2 VCS::LibCVS::Client::Request::version

Return the version of CVS running as server.

No data is required.

=cut

package VCS::LibCVS::Client::Request::version;
use vars ('@ISA');
@ISA =("VCS::LibCVS::Client::Request");
sub BEGIN { push @VCS::LibCVS::Client::Request::Valid_requests, "version"; }
sub required_data { return (); }

=head1 SEE ALSO

  VCS::LibCVS::Client
  VCS::LibCVS::Client::Request

=cut

1;
