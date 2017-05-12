#
# Copyright (c) 2003,2004,2005 Alexander Taler (dissent@0--0.org)
#
# All rights reserved. This program is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.
#

package VCS::LibCVS::Datum::Entry;

use strict;
use Carp;
use Time::Local;

=head1 NAME

VCS::LibCVS::Datum::Entry - A CVS datum for an RCS Entries Line

=head1 SYNOPSIS

  $string = VCS::LibCVS::Datum::Entry->new("/Client.pm/1.14/Mon Dec 16 16:49:16 2002//");

=head1 DESCRIPTION

An RCS style Entries Line:

  / NAME / VERSION / CONFLICT / OPTIONS / TAG_OR_DATE

This format is used in two places.  The CVS/Entries file, and in data returned
by the server.  The format can be slightly different in each of these cases.

In particular, the server can return a CONFLICT of "+=" when a new conflict is
being reported, but this shouldn't be stored in the Entries file.  Instead a
proper timestamp should be used.

=head1 SUPERCLASS

VCS::LibCVS::Datum

=cut

###############################################################################
# Class constants
###############################################################################

use constant REVISION => '$Header: /cvsroot/libcvs-perl/libcvs-perl/VCS/LibCVS/Datum/Entry.pm,v 1.19 2005/10/10 12:52:11 dissent Exp $ ';

use vars ('@ISA');
@ISA = ("VCS::LibCVS::Datum");

###############################################################################
# Class variables
###############################################################################

###############################################################################
# Private variables
###############################################################################

# $self->{Entry}         the full entry line
# $self->{Type}          the type of the entry, "Directory" or "File"
# $self->{FileName}      the name of the file to which this entry refers
# $self->{Revision}      the revision of the file
# $self->{Conflict}      conflict info
# $self->{Merge}         "No", "Merge" or "Conflict": if CVS merged the file
# $self->{Date}          from conflict info.  When CVS last changed the file
#                        in seconds since the epoch
# $self->{Options}       any sticky options
# $self->{Tag}           the sticky tag of the file

###############################################################################
# Class routines
###############################################################################

sub new {
  my $class = shift;
  my $that = $class->SUPER::new(@_);

  if ($that->{Entry} =~ m|^D/([^/]+)////$|) {
    $that->{Type} = "Directory";
    $that->{FileName} = $1;
  } elsif ($that->{Entry} =~ m|^/([^/]+)/([-0-9.]+)/([^/]*)/([^/]*)/([^/]*)$|) {
    $that->{Type} = "File";
    $that->{FileName} = $1;
    $that->{Revision} = $2;
    $that->{Conflict} = $3;
    $that->{Merge} = "No";   # default value
    $that->{Date} = 0;       # default value
    $that->{Options} = $4;
    $that->{Tag} = $5;

    # The Conflict field can look like this:
    # //  (empty) if the entry is being transmitted from the server
    # /Initial <filename>/ if it's a newly added file
    # /Result of merge/ if the file was merged without conflicts
    # /Result of merge+Sun Apr  6 02:47:18 2003/ for conflicts on merge
    # /+=/ for conflicts on merge, returned by server.  (Date is same as file)
    # /Sun Apr  6 02:24:57 2003/ to indicate when CVS made it up to date

    if ($that->{Conflict} =~ /^$/) {
    } elsif ($that->{Conflict} =~ /^Initial .*$/) {
      confess "Initial $that->{FileName} has non-0 revision"
        unless $that->{Revision} eq "0";
    } elsif ($that->{Conflict} =~ /^Result of merge$/) {
      $that->{Merge} = "Merge";
    } elsif ($that->{Conflict} =~ /^\+=$/) {
      $that->{Merge} = "Conflict";
    } elsif ($that->{Conflict} =~ /^Result of merge\+(.*)$/) {
      $that->{Merge} = "Conflict";
      $that->{Date} = _date_to_secs($1);
    } elsif ($that->{Conflict} =~ /^(.*)$/) {
      $that->{Date} = _date_to_secs($1);
    }

  } else {
    confess "Badly formatted entry line: " . $that->{Entry};
  }

  return $that;
}

###############################################################################
# Instance routines
###############################################################################

=head1 INSTANCE ROUTINES

=head2 B<name()>

$entry_name = $entry->name()

=over 4

=item return type: scalar string

=back

Returns the name of file to which the entry refers.

=cut

sub name {
  my $self = shift;
  return $self->{FileName};
}

=head2 B<get_tag()>

$tag = $entry->get_tag()

=over 4

=item return type: VCS::LibCVS::Datum::TagSpec

=back

Returns the tagspec for this entry, or undef if there's no tag.

=cut

sub get_tag {
  my $self = shift;
  return undef unless $self->{Tag};
  return VCS::LibCVS::Datum::TagSpec->new($self->{Tag});
}

=head2 B<get_revision()>

$revision = $entry->get_revision()

=over 4

=item return type: VCS::LibCVS::Datum::RevisionNumber

=back

Returns the revision number of this entry

=cut

sub get_revision {
  my $self = shift;
  # Remove the optional preceding '-', indicating scheduling for removal
  my ($rev) = ($self->{Revision} =~ /^-?(.*)/);
  return VCS::LibCVS::Datum::RevisionNumber->new($rev);
}

=head2 B<is_file()>

if ($entry->is_file()) {

=over 4

=item return type: boolean scalar

=back

Returns true if the entry represents a file

=cut

sub is_file {
  my $self = shift;
  return $self->{Type} eq "File";
}

=head2 B<is_directory()>

if ($entry->is_directory()) {

=over 4

=item return type: boolean scalar

=back

Returns true if the entry represents a directory

=cut

sub is_directory {
  my $self = shift;
  return $self->{Type} eq "Directory";
}

=head2 B<get_updated_time()>

$date = $entry->get_updated_time()

=over 4

=item return type: time in seconds since the epoch

=back

Returns the time that this file was last made up-to-date by CVS.  This is used
for checking if files are modified.  If the file modification time is less than
or equal to this time, then the file has not been modified.

If the file is the result of a merge, then no date is available, and 0 is
returned.

=cut

sub get_updated_time {
  my $self = shift;

  # if $self->{Merge} is other than "No" ("Merge" or "Conflict") then CVS did
  # not bring the file up-to-date on the last update, since it had to merge
  # changes.  So, just return 0 to show the file is modified.  Otherwise,
  # return the date.

  return ($self->{Merge} eq "No") ? $self->{Date} : 0;
}

=head2 B<get_conflict_time()>

$date = $entry->get_conflict_time()

=over 4

=item return type: time in seconds since the epoch

=back

Returns the time that conflict information was inserted into this file by CVS.
This is used for checking if conflicts have been resolved.  If the file
modification time is less than or equal to this time, then the file has
unresolved conflicts in it.

If the file did not have conflicts inserted into it, 0 is returned.

If this is a new conflict being reported, and the file has not yet been written
to disk, there is no time, so undef is returned.  This happens in Entry lines
being returned from the server.

=cut

sub get_conflict_time {
  my $self = shift;

  # if $self->{Merge} is other than "Conflict" (either "Merge" or "No") then no
  # conflicts have been inserted into this file.  So, just return 0 to show
  # there are no conflicts.  Otherwise, return the date.

  return ($self->{Merge} eq "Conflict") ? $self->{Date} : 0;
}

=head2 B<is_conflict()>

if ( $entry->is_conflict() ) . . .

=over 4

=item return type: boolean

=back

Return true if this Entry is for a file with a conflict.  This can ba a file on
disk with a conflict written into it.  Or one being returned from the server.

=cut

sub is_conflict {
  my $self = shift;

  return ($self->{Merge} eq "Conflict");
}


###############################################################################
# Private routines
###############################################################################

sub _data_names { return ("Entry"); }

# Convert the annoying string date to seconds since the epoch
#     Sun Apr  6 02:24:57 2003
sub _date_to_secs {
  my $date = shift;
  confess "Unexpected date format: $date"
    unless $date =~ /^\w{3} (\w{3})  ?(\d{1,2}) (\d\d):(\d\d):(\d\d) (\d{4})/;
  my ($month, $day, $hour, $minute, $second, $year) = ($1, $2, $3, $4, $5, $6);

  $month = {'Jan' => 0, 'Feb' => 1, 'Mar' => 2, 'Apr' => 3,
            'May' => 4, 'Jun' => 5, 'Jul' => 6, 'Aug' => 7,
            'Sep' => 8, 'Oct' => 9, 'Nov' => 10, 'Dec' => 11}->{$month};
  return timegm($second, $minute, $hour, $day, $month, $year);
}

=head1 SEE ALSO

  VCS::LibCVS::Datum

=cut

1;
