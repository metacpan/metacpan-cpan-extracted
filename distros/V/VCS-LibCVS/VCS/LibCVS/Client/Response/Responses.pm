#
# Copyright (c) 2003,2004,2005 Alexander Taler (dissent@0--0.org)
#
# All rights reserved. This program is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.
#

use strict;

=head1 NAME

VCS::LibCVS::Client::Response::Responses - Classes for many Responses

=head1 SYNOPSIS

  my @responses = Client::Response->read_from_server($server_conn);

=head1 DESCRIPTION

Each response of the CVS client protocol has its own class.  Many of them are
here.

Each response comes with a predetermined set of data, which is listed here for
each response.

=head1 SUPERCLASS

  VCS::LibCVS::Client::Response

=cut

# Each response has a BEGIN block where it pushes its name onto the list of
# valide responses.  This is so that the Valid-responses request knows what it
# can report as valid responses.

$VCS::LibCVS::Client::Response::Responses::REVISION = '$Header: /cvsroot/libcvs-perl/libcvs-perl/VCS/LibCVS/Client/Response/Responses.pm,v 1.16 2005/10/10 12:52:11 dissent Exp $ ';

###############################################################################
# ok
###############################################################################

=head1 CLASSES

=head2 VCS::LibCVS::Client::Response::ok

Last response in the group indicating success.

No args are expected.

=cut

package VCS::LibCVS::Client::Response::ok;
use vars ('@ISA');
@ISA =("VCS::LibCVS::Client::Response");
sub BEGIN { push @VCS::LibCVS::Client::Response::Valid_responses, "ok"; }
sub terminal { return 1; }
sub included_data { return (); }

###############################################################################
# error
###############################################################################

=head2 VCS::LibCVS::Client::Response::error

Last response in a group indicating failure.

  "String":  error message

=cut

package VCS::LibCVS::Client::Response::error;
use vars ('@ISA');
@ISA =("VCS::LibCVS::Client::Response");
sub BEGIN { push @VCS::LibCVS::Client::Response::Valid_responses, "error"; }
sub terminal { return 1; }

###############################################################################
# Valid-requests
###############################################################################

=head2 VCS::LibCVS::Client::Response::Valid_requests

List of requests which the server supports.  Client provides an interface to
check the results.

  "String": space delimited list of request names.

=cut

package VCS::LibCVS::Client::Response::Valid_requests;
use vars ('@ISA');
@ISA =("VCS::LibCVS::Client::Response");
sub BEGIN { push @VCS::LibCVS::Client::Response::Valid_responses, "Valid-requests"; }

###############################################################################
# E
###############################################################################

=head2 VCS::LibCVS::Client::Response::E

A message to be printed on stderr

  "String": the message

=cut

package VCS::LibCVS::Client::Response::E;
use vars ('@ISA');
@ISA =("VCS::LibCVS::Client::Response");
sub BEGIN { push @VCS::LibCVS::Client::Response::Valid_responses, "E"; }
sub get_errors { return shift->{Args}[0]{Text}; }

###############################################################################
# M
###############################################################################

=head2 VCS::LibCVS::Client::Response::M

A message to be printed on stdout

  "String": the message

=cut

package VCS::LibCVS::Client::Response::M;
use vars ('@ISA');
@ISA =("VCS::LibCVS::Client::Response");
sub BEGIN { push @VCS::LibCVS::Client::Response::Valid_responses, "M"; }
sub get_errors  { return shift->{Args}[0]{Text}; }
sub get_message { return shift->{Args}[0]{Text}; }

###############################################################################
# Mbinary
###############################################################################

=head2 VCS::LibCVS::Client::Response::Mbinary

A binary message to be printed on stdout

  "String": the message

=cut

package VCS::LibCVS::Client::Response::Mbinary;
use vars ('@ISA');
@ISA =("VCS::LibCVS::Client::Response");
sub BEGIN { push @VCS::LibCVS::Client::Response::Valid_responses, "Mbinary"; }
sub get_errors  { return shift->{Args}[0]{Text}; }
sub get_message { return shift->{Args}[0]{Text}; }

###############################################################################
# Copy-file
###############################################################################

=head2 VCS::LibCVS::Client::Response::Copy_file

Instructions to make a backup copy of a file

  "PathName": original file
  "FileName": new name of file

=cut

package VCS::LibCVS::Client::Response::Copy_file;
use vars ('@ISA');
@ISA =("VCS::LibCVS::Client::Response");
sub BEGIN { push @VCS::LibCVS::Client::Response::Valid_responses, "Copy-file"; }
sub included_data { return ("PathName", "FileName"); }

###############################################################################
# Set-sticky
###############################################################################

=head2 VCS::LibCVS::Client::Response::Set_sticky

Record a sticky tag for a file

  "PathName": the file
  "TagSpec": the sticky tag

=cut

package VCS::LibCVS::Client::Response::Set_sticky;
use vars ('@ISA');
@ISA =("VCS::LibCVS::Client::Response");
sub BEGIN { push @VCS::LibCVS::Client::Response::Valid_responses, "Set-sticky"; }
sub included_data { return ("PathName", "TagSpec"); }

###############################################################################
# Clear-sticky
###############################################################################

=head2 VCS::LibCVS::Client::Response::Clear_sticky

Remove a sticky tag from a file.

  "PathName": the file

=cut

package VCS::LibCVS::Client::Response::Clear_sticky;
use vars ('@ISA');
@ISA =("VCS::LibCVS::Client::Response");
sub BEGIN { push @VCS::LibCVS::Client::Response::Valid_responses, "Clear-sticky"; }
sub included_data { return ("PathName"); }

=head1 SEE ALSO

  VCS::LibCVS::Client
  VCS::LibCVS::Client::Response

=cut

1;
