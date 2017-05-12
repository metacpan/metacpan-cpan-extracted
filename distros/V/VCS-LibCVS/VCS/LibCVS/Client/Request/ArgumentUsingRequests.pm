#
# Copyright (c) 2003,2004,2005 Alexander Taler (dissent@0--0.org)
#
# All rights reserved. This program is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.
#

use strict;

=head1 NAME

VCS::LibCVS::Client::Request::ArgumentUsingRequests - Classes for many requests

=head1 SYNOPSIS

  my $ci_request = VCS::LibCVS::Client::Request::ci->new();
  $client->submit_request($ci_request);

=head1 DESCRIPTION

In the CVS client protocol, a request whose behaviour is modified by a previous
Argument request is called an "Argument Using Request".  Those requests have
their classes defined here, along with a common superclass.

As Argument Requests are sent, they are saved for the next Argument Using Request, whose behaviour they modify.  Once they've modified an Argument Using Request's behaviour they are forgotten, and will not affect any more requests.

The Argument Using Requests are recognizable as the familiar CVS commands: co,
up, ci, add, etc.

=head1 SUPERCLASS

  VCS::LibCVS::Client::Request

=cut

$VCS::LibCVS::Client::Request::ArgumentUsingRequests::REVISION = '$Header: /cvsroot/libcvs-perl/libcvs-perl/VCS/LibCVS/Client/Request/ArgumentUsingRequests.pm,v 1.18 2005/10/10 12:52:11 dissent Exp $ ';

###############################################################################
# ArgumentUsingRequest
###############################################################################

=head1 CLASSES

=head2 VCS::LibCVS::Client::Request::ArgumentUsingRequest

A common superclass for all the Argument Using Requests.  These requests take
no Data, so their constructors do not need any arguments.

=cut

package VCS::LibCVS::Client::Request::ArgumentUsingRequest;
use vars ('@ISA');
@ISA =("VCS::LibCVS::Client::Request");
sub required_data { return () };

=head2 B<uses_file_contents()>

if ($request->uses_file_contents())

=over 4

=item return type: boolean scalar

=back

Returns true if this argument using request needs the contents of local copies
of files to be sent to server.  "commit" is such a request.

If this returns true, each local file should have a Modified or equivalent
request issued for it, prior to issuing this request.

=cut

sub uses_file_contents {
  return 0;
}

=head2 B<uses_file_entry()>

if ($request->uses_file_entry())

=over 4

=item return type: boolean scalar

=back

Returns true if this argument using request needs the Entry information for
local files to be sent to server.  This information includes revision
information.  "update" is such a request.

If this returns true, each local file should have an Entry request issued for
it, prior to issuing this request.

This routine and uses_file_contents() are separate because the "tag" request
doesn't need the file contents.

=cut

sub uses_file_entry {
  return 0;
}

###############################################################################
# ci
###############################################################################

=head2 VCS::LibCVS::Client::Request::ci

Commit one or more files.

=cut

package VCS::LibCVS::Client::Request::ci;
use vars ('@ISA');
@ISA =("VCS::LibCVS::Client::Request::ArgumentUsingRequest");
sub BEGIN { push @VCS::LibCVS::Client::Request::Valid_requests, "ci"; }
sub uses_file_contents { return 1; }
sub uses_file_entry { return 1; }

###############################################################################
# diff
###############################################################################

=head2 VCS::LibCVS::Client::Request::diff

Find differences in one or more files.

=cut

package VCS::LibCVS::Client::Request::diff;
use vars ('@ISA');
@ISA =("VCS::LibCVS::Client::Request::ArgumentUsingRequest");
sub BEGIN { push @VCS::LibCVS::Client::Request::Valid_requests, "diff"; }
sub uses_file_contents { return 1; }
sub uses_file_entry { return 1; }

###############################################################################
# tag
###############################################################################

=head2 VCS::LibCVS::Client::Request::tag

Tag one or more files.

=cut

package VCS::LibCVS::Client::Request::tag;
use vars ('@ISA');
@ISA =("VCS::LibCVS::Client::Request::ArgumentUsingRequest");
sub BEGIN { push @VCS::LibCVS::Client::Request::Valid_requests, "tag"; }
sub uses_file_entry { return 1; }

###############################################################################
# status
###############################################################################

=head2 VCS::LibCVS::Client::Request::status

Report the status of one or more files.

=cut

package VCS::LibCVS::Client::Request::status;
use vars ('@ISA');
@ISA =("VCS::LibCVS::Client::Request::ArgumentUsingRequest");
sub BEGIN { push @VCS::LibCVS::Client::Request::Valid_requests, "status"; }
sub uses_file_contents { return 1; }
sub uses_file_entry { return 1; }

###############################################################################
# log
###############################################################################

=head2 VCS::LibCVS::Client::Request::log

Get the logs of one or more files.

=cut

package VCS::LibCVS::Client::Request::log;
use vars ('@ISA');
@ISA =("VCS::LibCVS::Client::Request::ArgumentUsingRequest");
sub BEGIN { push @VCS::LibCVS::Client::Request::Valid_requests, "log"; }

###############################################################################
# history
###############################################################################

=head2 VCS::LibCVS::Client::Request::history

Get the history of one or more files.

=cut

package VCS::LibCVS::Client::Request::history;
use vars ('@ISA');
@ISA =("VCS::LibCVS::Client::Request::ArgumentUsingRequest");
sub BEGIN { push @VCS::LibCVS::Client::Request::Valid_requests, "history"; }

###############################################################################
# annotate
###############################################################################

=head2 VCS::LibCVS::Client::Request::annotate

Get annotations of one or more files.

=cut

package VCS::LibCVS::Client::Request::annotate;
use vars ('@ISA');
@ISA =("VCS::LibCVS::Client::Request::ArgumentUsingRequest");
sub BEGIN { push @VCS::LibCVS::Client::Request::Valid_requests, "annotate"; }

###############################################################################
# co
###############################################################################

=head2 VCS::LibCVS::Client::Request::co

Checkout one or more files.

=cut

package VCS::LibCVS::Client::Request::co;
use vars ('@ISA');
@ISA =("VCS::LibCVS::Client::Request::ArgumentUsingRequest");
sub BEGIN { push @VCS::LibCVS::Client::Request::Valid_requests, "co"; }

###############################################################################
# export
###############################################################################

=head2 VCS::LibCVS::Client::Request::export

Export one or more files.

=cut

package VCS::LibCVS::Client::Request::export;
use vars ('@ISA');
@ISA =("VCS::LibCVS::Client::Request::ArgumentUsingRequest");
sub BEGIN { push @VCS::LibCVS::Client::Request::Valid_requests, "export"; }

###############################################################################
# update
###############################################################################

=head2 VCS::LibCVS::Client::Request::update

Update one or more files.

=cut

package VCS::LibCVS::Client::Request::update;
use vars ('@ISA');
@ISA =("VCS::LibCVS::Client::Request::ArgumentUsingRequest");
sub BEGIN { push @VCS::LibCVS::Client::Request::Valid_requests, "update"; }
sub uses_file_contents { return 1; }
sub uses_file_entry { return 1; }

###############################################################################
# add
###############################################################################

=head2 VCS::LibCVS::Client::Request::add

Schedule one or more files for addition.

=cut

package VCS::LibCVS::Client::Request::add;
use vars ('@ISA');
@ISA =("VCS::LibCVS::Client::Request::ArgumentUsingRequest");
sub BEGIN { push @VCS::LibCVS::Client::Request::Valid_requests, "add"; }

###############################################################################
# remove
###############################################################################

=head2 VCS::LibCVS::Client::Request::remove

Schedule one or more files for removal.

=cut

package VCS::LibCVS::Client::Request::remove;
use vars ('@ISA');
@ISA =("VCS::LibCVS::Client::Request::ArgumentUsingRequest");
sub BEGIN { push @VCS::LibCVS::Client::Request::Valid_requests, "remove"; }

###############################################################################
# rdiff
###############################################################################

=head2 VCS::LibCVS::Client::Request::rdiff

Find differences in one or more files, without the need for a working
directory.

=cut

package VCS::LibCVS::Client::Request::rdiff;
use vars ('@ISA');
@ISA =("VCS::LibCVS::Client::Request::ArgumentUsingRequest");
sub BEGIN { push @VCS::LibCVS::Client::Request::Valid_requests, "rdiff"; }
sub uses_file_contents { return 0; }
sub uses_file_entry { return 0; }

###############################################################################
# rlog
###############################################################################

=head2 VCS::LibCVS::Client::Request::rlog

Get the logs of one or more files.

=cut

package VCS::LibCVS::Client::Request::rlog;
use vars ('@ISA');
@ISA =("VCS::LibCVS::Client::Request::ArgumentUsingRequest");
sub BEGIN { push @VCS::LibCVS::Client::Request::Valid_requests, "rlog"; }

=head1 SEE ALSO

  VCS::LibCVS::Client
  VCS::LibCVS::Client::Request

=cut

1;
