#
# Copyright (c) 2003,2004,2005 Alexander Taler (dissent@0--0.org)
#
# All rights reserved. This program is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.
#

package VCS::LibCVS::FileRevision;

use strict;
use Carp;

=head1 NAME

VCS::LibCVS::FileRevision - A specific revision of a file managed by CVS.

=head1 SYNOPSIS

=head1 DESCRIPTION

Represents a single revision of a file managed by CVS.

=cut

###############################################################################
# Class constants
###############################################################################

use constant REVISION => '$Header: /cvsroot/libcvs-perl/libcvs-perl/VCS/LibCVS/FileRevision.pm,v 1.25 2005/10/10 12:52:11 dissent Exp $ ';

###############################################################################
# Class variables
###############################################################################

###############################################################################
# Private variables
###############################################################################

# $self->{BranchNumber}     VCS::LibCVS::Datum::RevisionNumber
#                The Branch revision number is stored in order to determine the
#                predecessor correctly.  This is necessary since a revision is
#                exists on all branches which sprout from it, as well as the
#                one to which it was first committed.  eg. revision 1.2 is on
#                branch 1, as well as branch 1.2.2.
# $self->{File}             VCS::LibCVS::RepositoryFile of this revision
# $self->{LogMessage}       VCS::LibCVS::Datum::LogMessage (fetched on demand)
# $self->{RevisionNumber}   VCS::LibCVS::Datum::RevisionNumber

###############################################################################
# Class routines
###############################################################################

=head1 CLASS ROUTINES

=head2 B<new()>

$file_rev = VCS::LibCVS::FileRevision->new($file, $revision, $branch_rev)

=over 4

=item return type: VCS::LibCVS::FileRevision

=item argument 1 type: VCS::LibCVS::RepositoryFile

=item argument 2 type: VCS::LibCVS::Datum::RevisionNumber

=item argument 3 type: optional VCS::LibCVS::Datum::RevisionNumber

=back

The revision number of the branch of this revision can be optionally specified.
If it's not, its revision number without the last field is used as the branch
number.  It is needed to correctly determine this revision's successor.

=cut

sub new {
  my $class = shift;
  my ($file, $revision, $branch) = @_;
  my $that = bless {}, $class;

  $that->{File} = $file;
  $that->{RevisionNumber} = $revision;
  if (! defined $branch) {
    $branch = $revision->branch_of();
  }
  $that->{BranchNumber} = $branch;

  return $that;
}

###############################################################################
# Instance routines
###############################################################################

=head1 INSTANCE ROUTINES

=head2 B<get_revision_number()>

$file = $file_rev->get_revision_number()

=over 4

=item return type: VCS::LibCVS::Datum::RevisionNumber

=back

=cut

sub get_revision_number {
  return shift->{RevisionNumber};
}

=head2 B<get_file()>

$file = $file_rev->get_file()

=over 4

=item return type: VCS::LibCVS::RepositoryFile

=back

=cut

sub get_file {
  return shift->{File};
}

=head2 B<get_file_branch()>

$file_branch = $file_rev->get_branch()

=over 4

=item return type: VCS::LibCVS::FileBranch

=back

=cut

sub get_file_branch {
  my $self = shift;
  return $self->{File}->get_branch($self->{RevisionNumber}->branch_of());
}

=head2 B<get_log_message()>

$message = $file_rev->get_log_message()

=over 4

=item return type: scalar string

=back

Returns the text of the log message for the commit that resulted in this
revision.

=cut

sub get_log_message {
  return shift->_get_log_message()->get_text();
}

=head2 B<get_committer()>

$committer = $file_rev->get_committer()

=over 4

=item return type: scalar string

=back

Returns the logname of whoever committed this particular revision.

=cut

sub get_committer {
  return shift->_get_log_message()->{Author};
}

=head2 B<get_time()>

$time = $file_rev->get_time()

=over 4

=item return type: scalar number

=back

Returns the time that this particular revision was committed, as seconds since
midnight January 1 1970.

=cut

sub get_time {
  my $self = shift;

  return VCS::LibCVS::parse_date($self->_get_log_message()->{Date});
}

=head2 B<get_time_string()>

$time_str = $file_rev->get_time_string()

=over 4

=item return type: scalar string

=back

Returns the time that this particular revision was committed, as the formatted
string returned by CVS.

=cut

sub get_time_string {
  return shift->_get_log_message()->{Date};
}

=head2 B<is_dead()>

if ($file_rev->is_dead()) { . . .

=over 4

=item return type: scalar boolean

=back

Returns true if and only if this revision is marked dead.

=cut

sub is_dead {
  return shift->_get_log_message()->{State} eq "dead";
}

=head2 B<get_contents()>

$data = $file_rev->get_contents()

=over 4

=item return type: VCS::LibCVS::Datum::FileContents

=back

Returns the contents of the particular revision.

=cut

# This function could use stdout mode ("-p") to avoid getting all the entries
# and stuff, but it would then receive the file as a series of "M" messages.
# This format of output worries me.

sub get_contents {
  my $self = shift;

  # Check if the file contents have been cached
  my ($cache, $c_key);
  if ($VCS::LibCVS::Cache_FileRevision_Contents_by_Repository) {
    $cache = $self->get_file->get_repository->{FileRevisionContentsCache};
    $c_key = $self->get_file->get_name.":".$self->{RevisionNumber}->as_string;
    return ($cache->{$c_key}) if ($cache->{$c_key});
  }

  # Specify which revision to get the contents of
  my $arg = [ "-r" . $self->{RevisionNumber}->as_string() ];

  # Generate and issue the command
  my $command = VCS::LibCVS::Command->new({},"update",$arg, [$self->get_file]);
  $command->issue($self->get_file()->get_repository());

  # The file is returned in an Updated response, as a FileContents Datum
  my @resps = $command->get_responses("VCS::LibCVS::Client::Response::Updated");
  confess "Not 1 Updated for " . $self->get_file->get_name unless (@resps == 1);

  # Cache and return the results
  if ($VCS::LibCVS::Cache_FileRevision_Contents_by_Repository) {
    ($cache->{$c_key}) = $resps[0]->data()->[3];
  }
  return $resps[0]->data()->[3];
}

=head2 B<get_predecessor()>

$pre_file_rev = $file_rev->get_predecessor()

=over 4

=item return type: VCS::LibCVS::FileRevision

=back

Returns the file revision that was right before this one, it's youngest
ancestor.  Return undef if it has no predecessor.

=cut

sub get_predecessor {
  my $self = shift;
  my $pre_rev = $self->{RevisionNumber}->get_predecessor();
  if ( defined $pre_rev) {
    return VCS::LibCVS::FileRevision->new($self->{File}, $pre_rev);
  } else {
    return;
  }
}

=head2 B<get_successor()>

$next_file_rev = $file_rev->get_successor()

=over 4

=item return type: VCS::LibCVS::FileRevision

=back

Returns the file revision on the same branch that comes right after this one,
it's oldest descendant.  Return undef if it has no successor.

XXXBUG: If a revision has been deleted, this will break.

=cut

sub get_successor {
  my $self = shift;

  # First determine the successor revision number.  If this revision is on a
  # branch which sprouts from it, then its successor's revision number has two
  # extra fields, and can't be determined directly from
  # Datum::RevisionNumber->get_successor(), so handle that case differently.

  my $suc_rev_num;
  if ($self->{BranchNumber}->equals($self->{RevisionNumber}->branch_of())) {
    $suc_rev_num = $self->{RevisionNumber}->get_successor();
  } else {
    $suc_rev_num = $self->{BranchNumber}->first_revision_of();
  }

  if (defined $self->{File}->_get_log_messages()->{$suc_rev_num->as_string()}) {
    return VCS::LibCVS::FileRevision->new($self->{File}, $suc_rev_num);
  } else {
    return;
  }
}

=head2 B<compare()>

$cmp = $file_rev1->compare($file_rev2)

=over 4

=item return type: integer, one of VCS::LibCVS::Datum::RevisionNumber::COMPARE_*

=item argument 1 type: VCS::LibCVS::FileRevision

=back

Compares this file revision with the argument.

The meanings of the return values are:

=over 4

=item COMPARE_EQUAL

They are the same revision.

=item COMPARE_ANCESTOR

The argument is an ancestor of this.

=item COMPARE_DESCENDANT

The argument is a descendant of this.

=item COMPARE_INCOMPARABLE

The argument is neither an ancestor, nor a descendant of this, and they aren't
equal.

=back

If they are FileRevisions of different files an exception is thrown.

See VCS::LibCVS::Datum::RevisionNumber for more information about the
comparison of revisions.

=cut

sub compare {
  my $self = shift;
  my $other = shift;

  if (! $self->{File}->equals($other->{File})) {
    confess "Can only compare revisions of the same file";
  }
  return $self->{RevisionNumber}->compare($other->{RevisionNumber});
}

=head2 B<equals()>

if ($frev1->equals($frev2)) {

=over 4

=item return type: boolean

=item argument 1 type: VCS::LibCVS::FileRevision

=back

Returns true if this and the other FileRevision are the same.

The same revision can be on multiple branches, so the branch it's on is not
compared.

=cut

sub equals {
  my $self = shift;
  my $other = shift;

  if (! $self->{File}->equals($other->{File})) {
    confess "Can only compare revisions of the same file";
  }
  return $self->{RevisionNumber}->equals($other->{RevisionNumber});
}

###############################################################################
# Private routines
###############################################################################

# get the Datum::LogMessage object for this particular file revision the
# difference between this and get_log_message is the return type.  I don't
# think it's appropriate for the external API to return a Datum::LogMessage
# object.

sub _get_log_message {
  my $self = shift;
  if (!defined $self->{LogMessage}) {
    my $rev_num_str = $self->{RevisionNumber}->as_string();
    $self->{LogMessage} = $self->{File}->_get_log_messages()->{$rev_num_str};
  }
  return $self->{LogMessage};
}

# Returns an Entry, like from the Entries file for this FileRevision.

sub _get_entry {
  my $self = shift;
  my $name = $self->{File}->get_name({'no_dir' => 1});
  my $revnum = $self->{RevisionNumber}->as_string();
  my $date = "Wed Jan 31 02:14:08 1973";
  return VCS::LibCVS::Datum::Entry->new("/$name/$revnum/$date//");
}

=head1 SEE ALSO

  VCS::LibCVS

=cut

1;
