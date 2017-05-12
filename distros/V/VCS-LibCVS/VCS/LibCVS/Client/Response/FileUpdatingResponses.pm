#
# Copyright (c) 2003,2004,2005 Alexander Taler (dissent@0--0.org)
#
# All rights reserved. This program is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.
#

use strict;

=head1 NAME

VCS::LibCVS::Client::Response::FileUpdatingResponses - Classes for many Responses

=head1 SYNOPSIS

  my @responses = Client::Response->read_from_server($server_conn);

=head1 DESCRIPTION

The file updating responses are those which indicate a change to the status of
a file in the working directory.  Each of them has a class here, along with a
common superclass.

Each response comes with a predetermined set of args, listed below.

=head1 SUPERCLASS

  VCS::LibCVS::Client::Response

=cut

$VCS::LibCVS::Client::Response::FileUpdatingResponses::REVISION = '$Header: /cvsroot/libcvs-perl/libcvs-perl/VCS/LibCVS/Client/Response/FileUpdatingResponses.pm,v 1.14 2005/10/10 12:52:11 dissent Exp $ ';

###############################################################################
# FileUpdatingResponse
###############################################################################

=head1 CLASSES

=head2 VCS::LibCVS::Client::Response::FileUpdateModifyingResponse

A common superclass for all the file updating responses.

=cut

package VCS::LibCVS::Client::Response::FileUpdatingResponse;
use vars ('@ISA');
@ISA =("VCS::LibCVS::Client::Response");

###############################################################################
# Checked-in
###############################################################################

=head2 VCS::LibCVS::Client::Response::Checked_in

  "PathName" "Entry"

=cut

package VCS::LibCVS::Client::Response::Checked_in;
use vars ('@ISA');
@ISA =("VCS::LibCVS::Client::Response::FileUpdatingResponse");
sub BEGIN { push @VCS::LibCVS::Client::Response::Valid_responses, "Checked-in";}
sub included_data { return ("PathName", "Entry"); }

###############################################################################
# New-entry
###############################################################################

=head2 VCS::LibCVS::Client::Response::New_entry

  "PathName" "Entry"

=cut

package VCS::LibCVS::Client::Response::New_entry;
use vars ('@ISA');
@ISA =("VCS::LibCVS::Client::Response::FileUpdatingResponse");
sub BEGIN { push @VCS::LibCVS::Client::Response::Valid_responses, "New-entry"; }
sub included_data { return ("PathName", "Entry"); }

###############################################################################
# Updated
###############################################################################

=head2 VCS::LibCVS::Client::Response::Updated

  "PathName" "Entry" "FileMode" "FileContents"

=cut

package VCS::LibCVS::Client::Response::Updated;
use vars ('@ISA');
@ISA =("VCS::LibCVS::Client::Response::FileUpdatingResponse");
sub BEGIN { push @VCS::LibCVS::Client::Response::Valid_responses, "Updated"; }
sub included_data { return ("PathName", "Entry", "FileMode", "FileContents"); }

###############################################################################
# Created
###############################################################################

=head2 VCS::LibCVS::Client::Response::Created

  "PathName" "Entry" "FileMode" "FileContents"

=cut

package VCS::LibCVS::Client::Response::Created;
use vars ('@ISA');
@ISA =("VCS::LibCVS::Client::Response::FileUpdatingResponse");
sub BEGIN { push @VCS::LibCVS::Client::Response::Valid_responses, "Created"; }
sub included_data { return ("PathName", "Entry", "FileMode", "FileContents"); }

###############################################################################
# Update-existing
###############################################################################

=head2 VCS::LibCVS::Client::Response::Update_existing

  "PathName" "Entry" "FileMode" "FileContents"

=cut

package VCS::LibCVS::Client::Response::Update_existing;
use vars ('@ISA');
@ISA =("VCS::LibCVS::Client::Response::FileUpdatingResponse");
sub BEGIN { push @VCS::LibCVS::Client::Response::Valid_responses, "Update-existing"; }
sub included_data { return ("PathName", "Entry", "FileMode", "FileContents"); }

###############################################################################
# Merged
###############################################################################

=head2 VCS::LibCVS::Client::Response::Merged

  "PathName" "Entry" "FileMode" "FileContents"

=cut

package VCS::LibCVS::Client::Response::Merged;
use vars ('@ISA');
@ISA =("VCS::LibCVS::Client::Response::FileUpdatingResponse");
sub BEGIN { push @VCS::LibCVS::Client::Response::Valid_responses, "Merged"; }
sub included_data { return ("PathName", "Entry", "FileMode", "FileContents"); }

###############################################################################
# Patched
###############################################################################

=head2 VCS::LibCVS::Client::Response::Patched

  "PathName" "Entry" "FileMode" "FileContents"

=cut

package VCS::LibCVS::Client::Response::Patched;
use vars ('@ISA');
@ISA =("VCS::LibCVS::Client::Response::FileUpdatingResponse");
sub BEGIN { push @VCS::LibCVS::Client::Response::Valid_responses, "Patched"; }
sub included_data { return ("PathName", "Entry", "FileMode", "FileContents"); }

###############################################################################
# Removed
###############################################################################

=head2 VCS::LibCVS::Client::Response::Removed

  "PathName"

=cut

package VCS::LibCVS::Client::Response::Removed;
use vars ('@ISA');
@ISA =("VCS::LibCVS::Client::Response::FileUpdatingResponse");
sub BEGIN { push @VCS::LibCVS::Client::Response::Valid_responses, "Removed"; }
sub included_data { return ("PathName"); }

###############################################################################
# Remove-entry
###############################################################################

=head2 VCS::LibCVS::Client::Response::Remove_entry

  "PathName"

=cut

package VCS::LibCVS::Client::Response::Remove_entry;
use vars ('@ISA');
@ISA =("VCS::LibCVS::Client::Response::FileUpdatingResponse");
sub BEGIN { push @VCS::LibCVS::Client::Response::Valid_responses, "Remove-entry"; }
sub included_data { return ("PathName"); }

=head1 SEE ALSO

  VCS::LibCVS::Client
  VCS::LibCVS::Client::Response

=cut

1;
