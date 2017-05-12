#
# Copyright (c) 2003,2004,2005 Alexander Taler (dissent@0--0.org)
#
# All rights reserved. This program is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.
#

use strict;

=head1 NAME

VCS::LibCVS::Client::Response::FileUpdateModifyingResponses - Classes for many Responses

=head1 SYNOPSIS

  my @responses = Client::Response->read_from_server($server_conn);

=head1 DESCRIPTION

A file update modifying response is one which affects the next file updating
response.  There is a class for each of them here, along with a common
superclass.

Each response comes with a predetermined set of args, listed below.

=head1 SUPERCLASS

  VCS::LibCVS::Client::Response

=cut

$VCS::LibCVS::Client::Response::FileUpdatModifyingResponses::REVISION = '$Header: /cvsroot/libcvs-perl/libcvs-perl/VCS/LibCVS/Client/Response/FileUpdateModifyingResponses.pm,v 1.11 2005/10/10 12:52:11 dissent Exp $ ';

###############################################################################
# FileUpdateModifyingResponse
###############################################################################

=head1 CLASSES

=head2 VCS::LibCVS::Client::Response::FileUpdateModifyingResponse

A common superclass for all the file update modifiying responses.

=cut

package VCS::LibCVS::Client::Response::FileUpdateModifyingResponse;
use vars ('@ISA');
@ISA =("VCS::LibCVS::Client::Response");

###############################################################################
# Mode
###############################################################################

=head2 VCS::LibCVS::Client::Response::Mode

The mode of the file.

  "FileMode"

=cut

package VCS::LibCVS::Client::Response::Mode;
use vars ('@ISA');
@ISA =("VCS::LibCVS::Client::Response::FileUpdateModifyingResponse");
sub BEGIN { push @VCS::LibCVS::Client::Response::Valid_responses, "Mode";}
sub included_data { return ("FileMode"); }

###############################################################################
# Mod-time
###############################################################################

=head2 VCS::LibCVS::Client::Response::Mod_time

The modification time of the file.

  "Time"

=cut

package VCS::LibCVS::Client::Response::Mod_time;
use vars ('@ISA');
@ISA =("VCS::LibCVS::Client::Response::FileUpdateModifyingResponse");
sub BEGIN { push @VCS::LibCVS::Client::Response::Valid_responses, "Mod-time";}
sub included_data { return ("Time"); }

=head1 SEE ALSO

  VCS::LibCVS::Client
  VCS::LibCVS::Client::Response
  VCS::LibCVS::Client::Response::FileUpdatingResponses

=cut

1;
