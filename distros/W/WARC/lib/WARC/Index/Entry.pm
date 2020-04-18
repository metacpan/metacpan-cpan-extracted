package WARC::Index::Entry;					# -*- CPerl -*-

use strict;
use warnings;

our @ISA = qw();

require WARC; *WARC::Index::Entry::VERSION = \$WARC::VERSION;

use Carp;

require WARC::Record::Stub;

=head1 NAME

WARC::Index::Entry - abstract base class for WARC::Index entries

=head1 SYNOPSIS

  use WARC;		# or ...
  use WARC::Index;

  # WARC::Index::Entry objects are returned from directly searching an index

  # match search criteria against entry
  $distance = $entry->distance( ... );
  @report = $entry->distance( ... );

  $index = $entry->index;	# get index containing entry
  $volume = $entry->volume;	# get WARC::Volume containing record
  $record = $entry->record;	# get WARC record

=head1 DESCRIPTION

=head2 Common Methods

Entries from all index systems support these methods:

=over

=item @report = $entry-E<gt>distance( ... )

=item $distance = $entry-E<gt>distance( ... )

In list context, return a detailed report mapping each search I<key> to a
distance value.  In scalar context, return an overall summary distance,
such that sorting entries by the return values of this method in ascending
order will place the closest matches at the top of the list.

A valid distance is non-negative.  Negative distance values indicate that
the record does not match the criteria at all.  An undefined value
indicates that the entry is from an index that does not store the
information needed to evaluate distance for that search key.  Undefined
values are ignored when computing the summarized distance, but the
summarized distance will be negative if any keys do not match at all and
itself undefined if none of the requested keys can be evaluated.

For details on available search keys, see the L<"Search Keys"
section|WARC::Collection/"Search Keys"> of the C<WARC::Collection> page.
If multiple values are given in an arrayref, the best match is reported.

=cut

sub distance {
  my $self = shift;

  unless (defined wantarray)
    { carp "calling 'distance' method in void context"; return }

  croak "no arguments given to 'distance' method"
    unless scalar @_;
  croak "odd number of arguments given to 'distance' method"
    if scalar @_ % 2;

  if (wantarray) { return $self->_distance_report(@_) }
  else		 { return $self->_distance_summary(@_) }
}

sub _distance_report {
  my $self = shift;
  my @report = ();

  for (my $i = 0; $i < @_; $i += 2)
    { push @report, $_[$i] => $self->_distance_for_item($_[$i] => $_[1+$i]) }

  return @report;
}

sub _distance_summary {
  my $self = shift;

  my $summary = 0;
  my $match = 1;
  my $seen = 0;

  while (@_) {
    my $distance = $self->_distance_for_item(splice @_, 0, 2);
    next unless defined $distance;
    $seen++;
    if ($distance < 0)	{ $match = 0 }
    else		{ $summary += $distance }
  }

  return undef unless $seen;
  return $match ? $summary : -(1+$summary);
}

# Single Point of Truth for index key definitions
our %_distance_value_map =
  ( time		=> [numeric => 'time'],
    record_id		=> [exact => 'record_id'],
    segment_origin_id	=> [exact => 'segment_origin_id'],
    url			=> [exact => 'url'],
    url_prefix		=> [prefix => 'url'],
  );

sub _distance_for_item {
  my $self = shift;
  my $item = shift;
  my @sought = (scalar shift);
  @sought = @{$sought[0]} if UNIVERSAL::isa($sought[0], 'ARRAY');

  croak "index distance requested for unknown item $item"
    unless defined $_distance_value_map{$item};
  my $actual = $self->value($_distance_value_map{$item}[1]);

  return undef unless defined $actual;

  my $mode = $_distance_value_map{$item}[0];

  my $distance = -1;
  if ($mode eq 'exact') {
    foreach my $sought (@sought) {
      $distance = 0 if $sought eq $actual;
    }
  } elsif ($mode eq 'numeric') {
    foreach my $sought (@sought) {
      my $here = abs($actual - $sought);
      $distance = $here if $distance < 0 || $here < $distance;
    }
  } elsif ($mode eq 'prefix') {
    foreach my $sought (@sought) {
      next unless $sought eq substr $actual, 0, length $sought;
      my $here = length($actual) - length($sought);
      $distance = $here if $distance < 0 || $here < $distance;
    }
  } else { die "unknown mode '$mode' for item '$item'" }
  return $distance;
}

=item $index = $entry-E<gt>index

Return the C<WARC::Index> containing this entry.

=cut

sub index {
  die __PACKAGE__." is an abstract base class and "
    .(ref shift)." must override the 'index' method"
}

=item $volume = $entry-E<gt>volume

Return the C<WARC::Volume> object representing the file in which this index
entry's record is located.

=cut

sub volume {
  die __PACKAGE__." is an abstract base class and "
    .(ref shift)." must override the 'volume' method"
}

=item $record = $entry-E<gt>record( ... )

Return the C<WARC::Record> this index entry represents. Arguments if given
are additional key =E<gt> value pairs for the record object.

=cut

sub record {
  my $self = shift;
  return new WARC::Record::Stub ($self->volume, $self->record_offset, @_);
}

=item $record_offset = $entry-E<gt>record_offset

Return the file offset at which this index entry's record is located.

=cut

sub record_offset {
  die __PACKAGE__." is an abstract base class and "
    .(ref shift)." must override the 'offset' method"
}

=item $value = $entry-E<gt>value( $key )

Return the value this index entry holds for a given search key.

=cut

sub value {
  die __PACKAGE__." is an abstract base class and "
    .(ref shift)." must override the 'value' method"
}

=item $tag = $entry-E<gt>tag

Return a tag for this index entry.  The exact format of the tag is
unspecified and platform-dependent.  Two index entries that refer to
different records are guaranteed (if the underlying system software behaves
correctly) to have different tag values, while two entries that refer to
the same record in the same volume will normally have the same tag value,
except in edge cases.

=cut

sub tag {
  my $self = shift;
  return (($self->volume->_file_tag).':'.($self->record_offset));
}

=back

=head2 Optional Methods

Some index entries may additionally support any of these methods:

=over

=item $next_entry = $entry-E<gt>next

Indexes with an inherent sequence of entries may provide a method to obtain
the next entry in the index.  Some index systems have this, while others do
not have a meaningful order amongst their entries.

=item $position = $entry-E<gt>entry_position

Indexes with an inherent sequence of entries may provide a method to obtain
some kind of index-specific entry number or location parameter.  This is
most useful for metaindexes to record the location of an index entry.

=back

=cut

1;
__END__

=head1 AUTHOR

Jacob Bachmeyer, E<lt>jcb@cpan.orgE<gt>

=head1 SEE ALSO

L<WARC>, L<WARC::Index>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2019 by Jacob Bachmeyer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
