package WARC::Record::Logical;					# -*- CPerl -*-

use strict;
use warnings;

require WARC::Record::FromVolume;
our @ISA = qw(WARC::Record::FromVolume);

use WARC; *WARC::Record::Logical::VERSION = \$WARC::VERSION;

use Carp;
use Math::BigInt;
use Scalar::Util qw();
use Symbol 'geniosym';

require WARC::Fields;
require WARC::Record::Logical::Block;
require WARC::Record::Logical::Heuristics;

# inherit _set

# inherit compareTo

# This implementation uses a hash as the underlying structure.

#  Keys inherited from WARC::Record base class (via WARC::Record::FromVolume):
#
#   fields

#  Keys inherited from WARC::Record::FromVolume base class:
#
#   collection (optional)
#	Parent WARC::Collection object, if available

#  Keys defined by this class:
#
#   segments
#	Array, each element is array of:
#	SEG_REC:	WARC::Record::FromVolume
#	SEG_BASE:	integer, logical offset of first octet in segment block
#	SEG_LENGTH:	integer, number of octets in segment data block

use constant {SEG_REC => 0, SEG_LENGTH => 1, SEG_BASE => 2};
use constant SEGMENT_INDEX => qw/SEG_REC SEG_LENGTH SEG_BASE/;

sub DESTROY { our $_total_destroyed;	$_total_destroyed++ }

sub _dbg_dump {
  my $self = shift;

  my $out = 'WARC logical record ['
    .(scalar @{$self->{segments}})." segments] containing:\n";
  my @out =
    map {s/^/  /gm; $_} map {$_->[SEG_REC]->_dbg_dump} @{$self->{segments}};
  $out .= join("\n", @out);

  return $out;
}

# inherit new

sub _read {
  my $class = shift;
  my $member = shift;

  my %ob = ();
  $ob{collection} = $member->{collection} if defined $member->{collection};

  my $member_segment_number = $member->field('WARC-Segment-Number');
  croak "attempting to load logical record for non-segmented record"
    unless $member_segment_number;

  # find the first segment
  my $first_segment = undef; my @clues = ();
 SEGMENT: {
    if ($member_segment_number == 1) {
      $first_segment = $member;	# <-- that was easy...
    } else {			# ... less easy:  go find the first segment...
      my $segment_origin_id = $member->field('WARC-Segment-Origin-ID');
      croak "record segment lacks required 'WARC-Segment-Origin-ID' field"
	unless $segment_origin_id;
      if (defined $member->{collection}
	  && $member->{collection}->searchable('record_id')) {
	$first_segment = $member->{collection}->search
	  (record_id => $segment_origin_id);
	next SEGMENT if defined $first_segment;
	carp "index failed to locate first segment by Record-ID";
	# ... and onwards to heuristics ...
      }
      ($first_segment, @clues) =
	WARC::Record::Logical::Heuristics::find_first_segment ($member);
    }
  }
  croak "failed to locate first segment of logical record"
    unless defined $first_segment;

  # find the other segments
  my @pool = ();
 SEGMENT: {
    if (defined $member->{collection}
	&& $member->{collection}->searchable('segment_origin_id')) {
      @pool = $member->{collection}->search
	(segment_origin_id => $first_segment->id);
      @pool = map {$_->[0]} sort {$a->[1] <=> $b->[1]}
	map {[$_, $_->field('WARC-Segment-Number')]} @pool;
      last SEGMENT if # we have all of the segments
	(@pool
	 && ($pool[-1]->field('WARC-Segment-Number') == (1+@pool))
	 && ($pool[-1]->field('WARC-Segment-Total-Length')));
      carp "index failed to locate all segments by Origin-ID";
	# ... and onwards to heuristics ...
    }
    push @pool, (WARC::Record::Logical::Heuristics::find_continuation
		 ($first_segment, @pool, @clues));
    # sort again in case heuristics added more records
    @pool = map {$_->[0]} sort {$a->[1] <=> $b->[1]}
      map {[$_, $_->field('WARC-Segment-Number')]} @pool;
  }
  croak "failed to locate any continuation segments for logical record"
    unless scalar @pool > 0;

  # assemble logical record segments
  my @record = ($first_segment);
  {
    my $i = 0;
    while ($i < @pool) {
      my $segment_number = $pool[$i]->field('WARC-Segment-Number');
      push @record, $pool[$i];
      $i++	# skip duplicate segments heuristics may have found
	while $i < @pool
	  && $segment_number == $pool[$i]->field('WARC-Segment-Number');
    }
  }

  # verify logical record
  for (my $i = 0; $i < @record; $i++) {
    croak "logical record segment missing or out-of-place"
      unless $record[$i]->field('WARC-Segment-Number') == (1+$i);
    croak "logical record segment not part of record (corrupted index?)"
      unless $i == 0
	|| $record[$i]->field('WARC-Segment-Origin-ID') eq $record[0]->id;
  }
  croak "final segment lacks required 'WARC-Segment-Total-Length' header"
    unless $record[-1]->field('WARC-Segment-Total-Length');

  # assemble logical record header
  my $fields = $record[0]->fields->clone;
  {
    # Set "Content-Length" to the total length
    $fields->field('Content-Length',
		   $record[-1]->field('WARC-Segment-Total-Length'));
    # Transfer any other non-segment-related headers that appear on the
    #  last segment and are not present at the first segment.
    foreach my $key (grep !m/^WARC-Segment-/, keys %{$record[-1]->fields}) {
      $fields->field($key, $record[-1]->field($key))
	unless defined $fields->field($key);
    }
    # Delete the block digest header, since it is from a segment.
    $fields->field('WARC-Block-Digest' => []);
    # Delete all segment-related headers
    my %fields; tie %fields, ref $fields, $fields;
    my @segment_headers = grep m/^WARC-Segment/, keys %fields;
    $fields->field($_ => []) for @segment_headers;
    untie %fields;
  }
  $fields->set_readonly;
  $ob{fields} = $fields;

  # assemble logical record data
  my @segments = ();
  {
    use integer;
    my $running_base = 0;
    for (my $i = 0; $i < @record; $i++) {
      my @row = ();

      $row[SEG_REC] = $record[$i];
      $row[SEG_LENGTH] = 0+$record[$i]->field('Content-Length');

      $running_base = Math::BigInt->new($running_base)
	if ((not ref $running_base)
	    && (($running_base + $row[SEG_LENGTH]) < $running_base));
      $row[SEG_BASE] = $running_base;

      $segments[$i] = \@row;
      $running_base += $row[SEG_LENGTH];
    }
  }
  $ob{segments} = \@segments;

  { our $_total_read;	$_total_read++ }

  my $self = bless \%ob, $class;

  $_->[SEG_REC]->{logical} = $self for @{$self->{segments}};
  Scalar::Util::weaken $_->[SEG_REC]->{logical} for @{$self->{segments}};

  return $self;
}

sub protocol { (shift)->{segments}[0][SEG_REC]->protocol }
sub volume { (shift)->{segments}[0][SEG_REC]->volume }
sub offset { (shift)->{segments}[0][SEG_REC]->offset }

sub logical { shift }

sub segments {
  if (wantarray) {
    return map {$_->[SEG_REC]} @{(shift)->{segments}}
  } else {
    return scalar @{(shift)->{segments}}
  }
}

sub next { (shift)->{segments}[-1][SEG_REC]->next }

sub open_block {
  my $self = shift;

  my $xhandle = Symbol::geniosym;
  tie *$xhandle, 'WARC::Record::Logical::Block', $self;

  return $xhandle;
}

sub open_continued { (shift)->open_block }

# inherit replay

# inherit open_payload

1;
__END__

=head1 NAME

WARC::Record::Logical - reassemble multi-segment records

=head1 SYNOPSIS

  use WARC::Record;

=head1 DESCRIPTION

This is an internal class used to implement C<WARC::Record> objects
representing continued records in WARC files.  A "continued record" is also
referred to as a "logical record" in the WARC specification and is a record
that has one or more "continuation" records to store a data block that is
too large to fit in a single WARC volume.

Note that a logical record will compare as equal to its first segment.

Methods in this class are documented as part of C<WARC::Record>.

=head1 CAVEATS

The code for handling segmented records that are longer than Perl's
integers can represent is relatively lightly tested and assumes that no
individual segment is longer than an integer can represent.  This will not
be a problem if the recommendation to limit WARC file size to 1GB is
followed, but may be an issue if larger files nonetheless use segmentation.

=head1 AUTHOR

Jacob Bachmeyer, E<lt>jcb@cpan.orgE<gt>

=head1 SEE ALSO

L<WARC>, L<WARC::Record>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2019 by Jacob Bachmeyer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
