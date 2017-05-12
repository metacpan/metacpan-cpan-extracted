#
# Copyright (c) 2003,2004,2005 Alexander Taler (dissent@0--0.org)
#
# All rights reserved. This program is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.
#

package VCS::LibCVS::RepositoryFile;

use strict;
use Carp;

=head1 NAME

VCS::LibCVS::RepositoryFile - A File in the CVS repository.

=head1 SYNOPSIS

=head1 DESCRIPTION

Represents a file in the CVS repository.

=head1 SUPERCLASS

VCS::LibCVS::RepositoryFileOrDirectory

=cut

###############################################################################
# Class constants
###############################################################################

use constant REVISION => '$Header: /cvsroot/libcvs-perl/libcvs-perl/VCS/LibCVS/RepositoryFile.pm,v 1.18 2005/10/10 12:52:11 dissent Exp $ ';

use vars ('@ISA');
@ISA = ("VCS::LibCVS::RepositoryFileOrDirectory");

###############################################################################
# Class variables
###############################################################################

###############################################################################
# Private variables
###############################################################################

# $self->{Tags}  A hash ref containing all the tags for this file
#                Keys are the names of tags as strings
#                Values are list refs: [ Datum::TagSpec, Datum::RevisionNumber ]
#                use _get_all_tags() to get at this
# $self->{Logs}  A hash ref containing all of the log messages for this file
#                Keys are revision numbers as strings
#                Values are Datum::LogMessage objects
#                use _get_log_messages() to get at this

###############################################################################
# Class routines
###############################################################################

sub new {
  my $class = shift;

  my $that = $class->SUPER::new(@_);

  my ($repo, $path) = @_;

  # Make sure that the file exists, by performing a repository action.  If it
  # doesn't exist, remove it from the cache.
  eval { $that->_load_log_messages(); };
  if ($@) {
    delete $repo->{RepositoryFileOrDirectoryCache}->{$that->{FileSpec}};
    confess($@);
  }

  return $that;
}


###############################################################################
# Instance routines
###############################################################################

=head1 INSTANCE ROUTINES

=head2 B<get_tags()>

$files_tags = $cvs_file->get_tags()

=over 4

=item return type: ref to list of scalar strings.

=back

Returns a list of all the non-branch tags on the file.

=cut

sub get_tags {
  my $self = shift;
  my @ret_tags;

  foreach my $taginfo (values (%{$self->_get_all_tags()})) {
    my ($tagspec, $revnum) = @{ $taginfo };
    if ($tagspec->get_type() eq VCS::LibCVS::Datum::TagSpec::TYPE_NONBRANCH) {
      push(@ret_tags, $tagspec->get_name());
    }
  }
  return \@ret_tags;
}

=head2 B<has_tag($name)>

if ($cvs_file->has_tag("foo_tag")) { . . .

=over 4

=item return type: scalar boolean

=back

Returns true if the file has a non-branch tag by that name.

=cut

sub has_tag {
  my $self = shift;
  my $name = shift;

  my $taginfo = $self->_get_all_tags()->{$name};
  if ($taginfo) {
    my ($tagspec, $revnum) = @{ $taginfo };
    return ($tagspec->get_type() eq VCS::LibCVS::Datum::TagSpec::TYPE_NONBRANCH);
  }
  return;
}

=head2 B<get_branches()>

$files_branches = $cvs_file->get_branches()

=over 4

=item return type: ref to list of VCS::LibCVS::FileBranch

=back

Returns a list of all the named branches of the file.

This includes the revision 1 trunk, with the name .TRUNK, but does not include
any other unnamed branches.

=cut

sub get_branches {
  my $self = shift;
  my @ret_branches;

  foreach my $taginfo (values (%{$self->_get_all_tags()})) {
    my $b = $self->_make_FileBranch($taginfo);
    push(@ret_branches, $b) if ($b);
  }
  # Put the trunk into the list
  push(@ret_branches, $self->_make_FileBranch_Trunk());
  return \@ret_branches;
}

=head2 B<get_branch($name_or_rev_or_branch)>

$files_branch = $cvs_file->get_branch("branch_1_1_4_stabilization")

=over 4

=item argument 1 type: scalar or VCS::LibCVS::Datum::RevisionNumber or VCS::LibCVS::Branch

=item return type: object of type VCS::LibCVS::FileBranch

=back

Return the specified branch, or undef if there is no such branch.  The branch
can be specified by a name, a branch revision number, or a Branch.

=cut

sub get_branch {
  my $self = shift;
  my $arg = shift;

  if (! ref $arg) {
    if ($arg eq ".TRUNK") { return $self->_make_FileBranch_Trunk(); }
    my $taginfo = $self->_get_all_tags()->{$arg};
    return $self->_make_FileBranch($taginfo) if $taginfo;

  } elsif ($arg->isa("VCS::LibCVS::Branch")) {
    if ($arg->get_name() eq ".TRUNK") { return $self->_make_FileBranch_Trunk(); }
    my $taginfo = $self->_get_all_tags()->{$arg->get_name()};
    return $self->_make_FileBranch($taginfo) if $taginfo;

  } elsif ($arg->isa("VCS::LibCVS::Datum::RevisionNumber")) {
    my $rev = $arg;
    if (! $rev->is_branch()) {
      confess "Not a branch revision: " . $rev->as_string();
    }
    if ($rev->is_trunk()) {
      return $self->_make_FileBranch_Trunk($rev);
    }
    foreach my $taginfo (values (%{$self->_get_all_tags()})) {
      if ($taginfo->[1]->equals($rev)) {
        return $self->_make_FileBranch($taginfo);
      }
    }
  } else {
    confess "get_branch() doesn't support objects of type " . ref $arg;
  }

  return;
}

=head2 B<get_revision()>

$files_rev = $cvs_file->get_revision($tag_or_revision)

=over 4

=item argument 1 type: scalar string

=item return type: VCS::LibCVS::FileRevision

=back

Returns the revision of the file specified by the named tag or revision number,
or raises an error if there is no such tag or revision.

The BASE tag is not supported, since this is a repository object with no
knowledge of the working directory.  The WorkingFile object will provide the
necessary information.

=cut

sub get_revision {
  my $self = shift;
  my $tag_or_rev = shift;
  my $rev;

  my $taginfo = $self->_get_all_tags()->{$tag_or_rev};
  if ($taginfo && 
      $taginfo->[0]->get_type() eq VCS::LibCVS::Datum::TagSpec::TYPE_NONBRANCH) {
    $rev = $taginfo->[1];
  } else {
    $rev = VCS::LibCVS::Datum::RevisionNumber->new($tag_or_rev);
  }

  return VCS::LibCVS::FileRevision->new($self, $rev);
}

###############################################################################
# Private routines
###############################################################################

# get the tag info from private variables
# use this function instead of direct access to make it easier to add caching
sub _get_all_tags {
  my $self = shift;

  $self->_load_tags();
  return $self->{Tags};
}

# loads the tag info into the private variable Tags
sub _load_tags {
  my $self = shift;

  my $loginfo = $self->_get_loginfo_from_server({NoLog => 1});

  # The tag info is returned in this format:
  #
  # symbolic names:
  #       REGULAR_TAG: 1.2.2.1
  #       foo_branch: 1.2.0.2
  #
  # So it is processed by traversing the responses until we hit the string
  # "symbolic names:", after which we read them as tags.

  # In addition, the head revision is found elsewhere in a line of this format:
  # head: 1.2
  # It is used to put the HEAD tag in.

  my %tags;
  my $in_tags = 0;  # true after the "symbolic names:" message
  foreach my $line (@$loginfo) {
    if ($in_tags) {
      # check if the line specifies a tag
      # if it doesn't, then there are no more
      if ($line !~ /^\s+(.*): ([0-9.]*)$/) {
        last;
      } else {
        my ($tag_string, $rev_string) = ($1, $2);
        my $rev = VCS::LibCVS::Datum::RevisionNumber->new($rev_string);
        my $tagspec = VCS::LibCVS::Datum::TagSpec->
          new(($rev->is_branch() ? "T" : "N") . $tag_string);
        $tags{$tag_string} = [ $tagspec, $rev ];
      }
    } elsif ($line eq "symbolic names:") {
      $in_tags = 1;
    } elsif ($line =~ /head: ([0-9.]*)/) {
      my $rev = VCS::LibCVS::Datum::RevisionNumber->new($1);
      my $tagspec = VCS::LibCVS::Datum::TagSpec->new("NHEAD");
      $tags{"HEAD"} = [ $tagspec, $rev ];
    }
  }
  $self->{Tags} = \%tags;
}

# make a FileBranch from a $self->{Tags} entry.  Return undef if it's not a
# BRANCH tag.

sub _make_FileBranch {
  my ($self, $tags_entry) = @_;

  my ($tagspec, $revnum) = @{ $tags_entry };

  if ($tagspec->get_type() eq VCS::LibCVS::Datum::TagSpec::TYPE_BRANCH) {
    return VCS::LibCVS::FileBranch->new($self, $tagspec, $revnum);
  }
  return;
}

# make a FileBranch object for the trunk.

sub _make_FileBranch_Trunk {
  my $self = shift;
  my $rev = shift || VCS::LibCVS::Datum::RevisionNumber->new("1");
  my $tagspec = VCS::LibCVS::Datum::TagSpec->new("T.TRUNK");
  return VCS::LibCVS::FileBranch->new($self, $tagspec, $rev);
}

# get the log messages from private variables
# use this function instead of direct access to make it easier to add caching
sub _get_log_messages {
  my $self = shift;

  $self->_load_log_messages();
  return $self->{Logs};
}

# loads the log messages into the private variable Logs
sub _load_log_messages {
  my $self = shift;

  my $loginfo = $self->_get_loginfo_from_server({NoTag => 1});

  # The log messages are returned in this format:

  # <header stuff>
  # description:
  # ----------------------------
  # revision 1.2
  # date: 2002/11/13 02:29:46;  author: dissent;  state: Exp;  lines: +1 -0
  # branches:  1.2.2;
  # logmessage
  # ----------------------------
  # revision 1.1
  # date: 2002/11/13 02:29:33;  author: dissent;  state: Exp;
  # *** empty log message ***
  # ----------------------------
  # revision 1.2.2.1
  # date: 2003/01/11 16:39:04;  author: dissent;  state: Exp;  lines: +1 -0
  # mm
  #
  # So it is processed by traversing the responses until we hit the string
  # "description:", after which log messages are split by ------ lines

  confess "Empty log, $self->{FileSpec} is a directory." if ( @$loginfo == 0);

  # Discard the header, everything up to and including the "description:" line
  while ( @$loginfo ) {
    # Validate that this loginfo is for the correct file.  Generally this check
    # is not needed, but may be useful to help catch problems.  There is one
    # case where it is needed, explained below [1].
    if ($loginfo->[0] =~ /^Working file: (.*)/) {
      if ($1 ne $self->{FileSpec}) {
        confess "Bad Working file in log, $self->{FileSpec} is a directory.";
      }
    }
    last if (shift @$loginfo) eq "description:";
  }
  # the last line will be a bunch of ==, remove it now:
  my $last = pop @$loginfo;
  confess "Bad final log line: $last" unless $last =~ /={77}/;

  # Collect all the log messages in a hash from revision to log message.
  my %logs;
  my $log_entry_sep = qr/-{28}/;

  # Collect the lines that make up a single log message into the
  # @log_mess_array, and use it to create a LogMessage.
  while (@$loginfo) {
    my $f_l = shift @$loginfo;
    confess "Bad log entry separator: $f_l" unless $f_l =~ $log_entry_sep;
    my @log_mess_array;
    while (@$loginfo) {
      last if (($loginfo->[0] =~ $log_entry_sep ) &&
               ($loginfo->[1] =~ /^revision [0-9.]*/ ));
      push (@log_mess_array, (shift @$loginfo));
    }
    my $log_mess = VCS::LibCVS::Datum::LogMessage->new(\@log_mess_array);
    $logs{$log_mess->get_revision()->as_string()} = $log_mess;
  }
  $self->{Logs} = \%logs;
}

# get various bits of the log info.
# may pass boolean options to select which bits to return:
# $file->_get_loginfo_from_server({ NoTags => 1, NoLog => 0 })
# it returns the loginfo as a ref to an array of lines
sub _get_loginfo_from_server {
  my $self = shift;
  my $options = shift || {};

  # To turn off retrieving log info, ask only for revisions that precede 1.1
  my $args = [ $options->{NoLog} ? "-r::1.1" : (),
               $options->{NoTags} ? "-N" : () ];

  my $command = VCS::LibCVS::Command->new({}, "log", $args, [$self]);
  $command->issue($self->{Repository});

  # Return the responses as a list of lines
  return [ $command->get_messages() ];
}

# Directory names for reporting to the server.
# Routine called in Command.pm, see there for more details.
sub _get_repo_dirs {
  my $self = shift;
  # Use the repository dir as the working directory required by the protocol
  my $l_dir = $self->get_name({no_base => 1});
  my $r_dir = $self->get_name({abs => 1, no_base => 1});
  return [ $l_dir, $r_dir ];
}

=head1 SEE ALSO

  VCS::LibCVS

=cut

1;

### Footnotes

# [1] The check _load_log_messages() that the log messages match the file is
# used in the following circumstances.  RepositoryFileOrDirectory->find() calls
# the RepositoryFile constructor and if it fails concludes that the argument in
# fact represents a directory.  The constructor fails because
# _load_log_messages() fails to retrieve any log messages for the directory.
# No log messages are returned because no Directory request is submitted for
# the subdirectory in the cvsclient protocol, only its parent.  However, in the
# case of the root directory of the repository, a Directory request _is_
# submitted, because this is always done in order not to break the protocol,
# and so some log messages are returned.  Without this check the constructor
# would mistakenly conclude that "." is a file and not a directory.
