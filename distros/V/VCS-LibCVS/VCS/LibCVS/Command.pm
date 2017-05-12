#
# Copyright (c) 2003,2004,2005 Alexander Taler (dissent@0--0.org)
#
# All rights reserved. This program is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.
#

package VCS::LibCVS::Command;

use strict;
use Carp;

=head1 NAME

VCS::LibCVS::Command - A command to send to the server.

=head1 SYNOPSIS

=head1 DESCRIPTION

VCS::LibCVS::Command represents a single command sent to the server, and
provides access to the response.

It is for internal LibCVS use only.

=cut

###############################################################################
# Class constants
###############################################################################

use constant REVISION => '$Header: /cvsroot/libcvs-perl/libcvs-perl/VCS/LibCVS/Command.pm,v 1.15 2005/10/10 12:19:18 dissent Exp $ ';

###############################################################################
# Class variables
###############################################################################

###############################################################################
# Private variables
###############################################################################

# $self->{Options}    Hash ref of options with which the command was created.
# $self->{AURequest}  VCS::LibCVS::Client::Request::ArgumentUsingRequest
# $self->{CVSOptions} List ref of VCS::LibCVS::Client::Request::Argument
# $self->{Files}      List ref of VCS::LibCVS::[Working]FileOrDirectory
# $self->{Responses}  List ref of VCS::LibCVS::Client::Response

###############################################################################
# Class routines
###############################################################################

=head1 CLASS ROUTINES

=head2 B<new()>

$command = VCS::LibCVS::Command->new($opts, $command, $opts, $files_and_dirs)

=over 4

=item return type: VCS::LibCVS::Command

Newly created command class.

=item argument 1 type: ref to hash of options

No options currently supported.

=item argument 2 type: scalar string

The CVS command to call, such as "update", "ci", etc.  Strictly, it is the
name of one of the subclasses of
VCS::LibCVS::Client::Request::ArgumentUsingRequest.

=item argument 3 type: ref to list of scalar strings

Options to pass to the CVS server, such as "-r1.1", "-kb".  These are pretty
much the same as the options passed on the cvs command line.

=item argument 4 type: ref to list of files and directories

The files and directories to process for the command.  They are objects of any
of these types:
  VCS::LibCVS::RepositoryFile
  VCS::LibCVS::RepositoryDirectory
  VCS::LibCVS::WorkingFile
  VCS::LibCVS::WorkingDirectory
  VCS::LibCVS::FileRevision

=back

Creates a new Command.  You must then issue the command on a repository.

=cut

sub new {
  my $class = shift;
  my $that = bless {}, $class;

  $that->{Options} = shift;
  my $aurequest_class_name = "VCS::LibCVS::Client::Request::" . shift;
  $that->{AURequest} = "$aurequest_class_name"->new();
  $that->{CVSOptions} =
    [ map({ VCS::LibCVS::Client::Request::Argument->new($_); } @{shift()}) ];
  $that->{Files} = shift;

  return $that;
}

###############################################################################
# Instance routines
###############################################################################

=head1 INSTANCE ROUTINES

=head2 B<issue()>

$command->issue($repo)

=over 4

=item return type: undef

=item argument 1 type: VCS::LibCVS::Repository

The repository upon which the command is issued.

=back

Issues the command on the repository.  In case of error an exception is
thrown.

To get the reponses, use get_responses() or get_messages().

=cut

# From the cvs protocol docs:
#
#      normal usage is to send `Directory' for
#      each directory in which there will be an `Entry' or `Modified',
#      and then a final `Directory' for the original directory, then the
#      command.
#
# 'Entry' and 'Modified' are requests.  I have also found it necessary to send
# a 'Directory' for each directory in which an argument request appears.  The
# following works for a subdirectory:
#    Argument  "testdir1/subdir1"
#    Directory ["testdir1/subdir1", "$rep_dir/testdir1/subdir1"]
#    Directory [".", "$rep_dir"]

sub issue {
  my $self = shift;
  my $repo = shift;

  ### Open the connection to the server

  # Get a client object for the repository.  _get_client() requires the name
  # of a server directory, which is fetched from a FileOrDirectory object
  # found in {Files}.
  my $client;
  {
    my $f = $self->{Files}->[0];
    if ($f->isa("VCS::LibCVS::FileRevision")) {
      $f = $f->get_file();
    }
    $client = $repo->_get_client($f->_get_repo_dirs()->[1]);
  }

  ### Send CVS options
  foreach my $opt (@{$self->{CVSOptions}}) {
    $client->submit_request($opt);
  }

  ### Send filename and directory args

  # Each consists of an Argument request, followed by a matching Directory
  # request.  It all ends with a final Directory request for the "original
  # directory", presumably the current working directory.  I assume that all
  # files are named relative to this.

  # All of the file and directory objects implement the _get_repo_dirs()
  # routine, to get the information for generating a Directory request to send
  # to the server.  The routine returns a ref to a list containing two scalars,
  # the working directory and repository directory, as needed for the Directory
  # request.

  # %dirs_sent keeps track of the Directory requests that have been sent to the
  # server
  my %dirs_sent;

  foreach my $f (@{$self->{Files}}) {

    if ( $f->isa("VCS::LibCVS::WorkingDirectory") ) {
      confess "WorkingDirectory not supported.  See bug #14191.";
    }

    # Make sure that $f is a FileOrDirectory object, but keep any FileRevision
    # object in order to generate an Entries line later.
    my $fr;
    if ($f->isa("VCS::LibCVS::FileRevision")) {
      $fr = $f;
      $f = $fr->get_file();
    }

    my $fnreq = VCS::LibCVS::Client::Request::Argument->new([$f->get_name]);
    $client->submit_request($fnreq);

    # Save bandwidth by only sending directory requests once
    my $dirs = $f->_get_repo_dirs;
    if (!$dirs_sent{$dirs->[0]}) {
      $dirs_sent{$dirs->[0]} = $dirs->[1];
      my $dreq = VCS::LibCVS::Client::Request::Directory->new($dirs);
      $client->submit_request($dreq);
    }

    # For some requests ( such as "ci" and "diff" ) the server needs
    # information about the local state of the files in the form of Entries
    # lines and the file contents.  This information is only sent if the
    # Request object indicates that it is needed.  Some Requests, notably
    # update, use file contents and entry requests, but don't require them.

    if ($self->{AURequest}->uses_file_entry()) {
      my $e;
      if (defined $fr) {
        # A FileRevision is being processed so get the entry from there.
        $e = $fr->_get_entry();
      } elsif ( $f->isa("VCS::LibCVS::WorkingFile") ) {
        $e = $f->_get_entry();
      }
      if (defined $e) {
        $client->submit_request(VCS::LibCVS::Client::Request::Entry->new([$e]));
      }
    }

    if ($self->{AURequest}->uses_file_contents()
        && $f->isa("VCS::LibCVS::WorkingFile")) {
      my $m = [$f->get_name({no_dir => 1}), $f->_get_mode, $f->_get_contents];
      my $m_req = (VCS::LibCVS::Client::Request::Modified->new( $m ));
      $client->submit_request($m_req);
    }
  }

  # Send the original directory request

  # This could be the current directory, or the common ancestor of all the sent
  # directories.  We use the root directory.

  # If it's already been sent with one of the previous arguments, just resend
  # that one.  If it wasn't already sent, we should look in the /CVS Admin
  # directory to get the repository for the current directory.  But that
  # doesn't match our paradigm very well, and it doesn't really matter, because
  # we know that none of the files we are interested in live in the current
  # directory.  So, we just send the cwd (".") and the repository root.

  my $r_dir = $dirs_sent{"."} || $repo->get_root()->get_dir();
  my $origd_req = VCS::LibCVS::Client::Request::Directory->new([".","$r_dir"]);
  $client->submit_request($origd_req);

  ### Send the command request
  my @resps = $client->submit_request($self->{AURequest});

  ### Check responses

  # Throw an exception in case of error
  if (($resps[-1]->isa("VCS::LibCVS::Client::Response::error"))) {
    my $errors;
    foreach my $resp (@resps) { $errors .= ($resp->get_errors() || ""); };
    confess "Request failed: \"$errors\"";
  }

  # No error, so just store the responses and return.
  $self->{Responses} = \@resps;

  return;
}

=head2 B<get_responses()>

@responses = $command->get_responses($type)

=over 4

=item return type: list of VCS::LibCVS::Client::Response

=item argument 1 type: scalar type string

The type of responses requested.

=back

Returns the responses of the specified type.  If the type is undef or the empty
string, all responses are returned.

=cut

sub get_responses {
  my $self = shift;
  my $c = shift || "VCS::LibCVS::Client::Response";

  return map { $_->isa($c) ? $_ : () } @{ $self->{Responses} };
}

=head2 B<get_messages()>

@messages = $command->get_messages($pattern)

=over 4

=item return type: list of scalar strings

=item argument 1 type: scalar string or Regexp

Optional Regexp that returned messages match.

=back

Goes through all the M reponses and returns the contents of those which match
the provided regexp.

=cut

sub get_messages {
  my $self = shift;
  my $p = shift || "^";

  return map {
    ($_->get_message() =~ /$p/) ? $_->get_message : ();
  } $self->get_responses("VCS::LibCVS::Client::Response::M");
}

=head2 B<get_errors()>

@messages = $command->get_errors($pattern)

=over 4

=item return type: list of scalar strings

=item argument 1 type: scalar string or Regexp

Optional Regexp that returned errors match.

=back

Goes through all the E reponses and returns the contents of those which match
the provided regexp.

=cut

sub get_errors {
  my $self = shift;
  my $p = shift || "^";

  return map {
    ($_->get_errors() =~ /$p/) ? $_->get_errors : ();
  } $self->get_responses("VCS::LibCVS::Client::Response::E");
}

=head2 B<get_files()>

@files = $command->get_files()

=over 4

=item return type: list of VCS::LibCVS::Client::Response

=back

Goes through all the reponses and returns those which are file transmissions.
They are responses of type "Checked-in", "Merged", "Updated", . . .

=cut

sub get_files {
  my $self = shift;

  return map {
    $self->get_responses("VCS::LibCVS::Client::Response::" . $_ );
  } ("Checked_in", "Merged", "Updated");
}

###############################################################################
# Private routines
###############################################################################

=head1 SEE ALSO

  VCS::LibCVS

=cut

1;
